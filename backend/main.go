package main

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"zxy/config"
	"zxy/interface/rest"
	zxyWs "zxy/interface/websocket"
	addonsrepository "zxy/repository/addons_repository"
	localtmdbrepository "zxy/repository/local_tmdb_repository"
	playbackrepository "zxy/repository/playback_repository"
	sessionrepository "zxy/repository/session_repository"
	userrepository "zxy/repository/user_repository"
	addonusecase "zxy/usecase/addon_usecase"
	progressusecase "zxy/usecase/progress_usecase"
	tmdbusecase "zxy/usecase/tmdb_usecase"
	traktusecase "zxy/usecase/trakt_usecase"
	userusecase "zxy/usecase/user_usecase"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
	"github.com/redis/go-redis/v9"
)

func main() {
	fmt.Println("Zxy started")
	cwd, err := os.Getwd()
	if err != nil {
		fmt.Println("Error getting cwd ", err)
		return
	}
	cfg, err := config.GetConfig(filepath.Join(cwd, ".env"))
	if err != nil {
		fmt.Println("Error loading env ", err)
		return
	}

	if cfg.TmdbUrl == "" {
		fmt.Println("Invalid TMDB url")
		return
	}
	db, err := sql.Open("postgres", cfg.PosgresUrl)
	if err != nil {
		fmt.Println("Error connecting to postgres db ", err)
		return
	}
	defer db.Close()
	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		fmt.Println("Error getting postgres driver ", err)
		return
	}

	mgr, err := migrate.NewWithDatabaseInstance(
		fmt.Sprintf("file:///%s", cfg.MigrationsPath),
		"postgres",
		driver,
	)
	if err != nil {
		fmt.Println("Error creating migrate instance", err)
		return
	}

	err = mgr.Up()
	if err != nil {
		if err != migrate.ErrNoChange {
			fmt.Println("Error running migrate instance ", err)
			return
		}
	}

	fmt.Println("Successfully ran migrations")

	localTmdb, err := sql.Open("postgres", cfg.LocalTmdbUrl)
	if err != nil {
		fmt.Println("Error connecting to local tmdb ", err)
		return
	}
	defer localTmdb.Close()

	cacheDBID, err := strconv.Atoi(cfg.RedisCacheDb)
	if err != nil {
		fmt.Println("Invalid redis cache db")
		return
	}

	cacheRDB := redis.NewClient(&redis.Options{
		Addr:     cfg.RedisAddress,
		Password: cfg.RedisPassword,
		DB:       cacheDBID,
	})
	defer cacheRDB.Close()
	_, err = cacheRDB.Ping(context.Background()).Result()
	if err != nil {
		fmt.Println("Unable to connect to cache redis db", err)
		return
	}

	watchSessionDBID, err := strconv.Atoi(cfg.RedisWatchSessionDb)
	if err != nil {
		fmt.Println("Invalid redis watch session db")
		return
	}

	watchSessionDB := redis.NewClient(&redis.Options{
		Addr:     cfg.RedisAddress,
		Password: cfg.RedisPassword,
		DB:       watchSessionDBID,
	})
	defer watchSessionDB.Close()
	_, err = watchSessionDB.Ping(context.Background()).Result()
	if err != nil {
		fmt.Println("Unable to connect to watch session redis db", err)
		return
	}

	userRepo := userrepository.New(db)
	sessionRepo := sessionrepository.New(db)
	playbackRepo := playbackrepository.New(db)
	addonRepo := addonsrepository.New(db)
	localTmdbRepo := localtmdbrepository.New(localTmdb)

	wsHandler := zxyWs.New()

	tmdbUc := tmdbusecase.New(cfg.TmdbUrl, localTmdbRepo, cfg.TraktKey, cfg.TmdbAT, cacheRDB)
	addonuc, err := addonusecase.New(
		addonRepo,
		cfg.AIOTemplatePath,
		cfg.AIOInstances,
		cfg.TmdbAT,
		db,
		userRepo,
		cfg.ZxyUrl,
		cfg.EncrKey,
		cfg.ZxyAioInstance,
		cfg.AioConfigUid,
		cfg.AioConfigPwd,
	)
	if err != nil {
		return
	}

	traktUc := traktusecase.New(
		cfg.TraktKey,
		cfg.TraktSecret,
		userRepo,
		playbackRepo,
		cfg.TraktRedirectUri,
		cacheRDB,
	)
	userUc := userusecase.New(db, userRepo, sessionRepo, playbackRepo, addonRepo, addonuc, traktUc)
	progressUc := progressusecase.New(
		db,
		tmdbUc,
		playbackRepo,
		traktUc,
		watchSessionDB,
		localTmdbRepo,
	)
	restInterface := rest.New(
		addonuc,
		tmdbUc,
		userUc,
		userRepo,
		sessionRepo,
		progressUc,
		cfg.EncrKey,
		wsHandler,
		traktUc,
	)
	defer restInterface.Exit()
	router := restInterface.SetupRoutes()
	err = http.ListenAndServe(fmt.Sprintf(":%s", cfg.Port), router)
	if err != nil {
		fmt.Println("Error creating http server ", err)
	}
}
