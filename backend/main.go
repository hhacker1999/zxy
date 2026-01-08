package main

import (
	"database/sql"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"zxy/config"
	"zxy/interface/rest"
	addonusecase "zxy/usecase/addon_usecase"
	tmdbusecase "zxy/usecase/tmdb_usecase"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
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

	addonuc := addonusecase.New(
		"http://192.168.1.50:3000/stremio/8f0eb1de-911b-4e0d-92c8-ece4348a7556/eyJpIjoiTUNMN0d4UnFhZjNUVW1ucjlSU2w3UT09IiwiZSI6InVDREt3Y3pEZU5FVW1CR0VLWFNqeFRuTFVkdEV0THNOaDhQbkM0a3Jud289IiwidCI6ImEifQ",
	)
	if cfg.TmdbUrl == "" {
		fmt.Println("Invalid TMDB url")
		return
	}
	db, err := sql.Open("postgres", cfg.PosgresUrl)
	if err != nil {
		fmt.Println("Error connecting to postgres db ", err)
		return
	}
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

	tmdbUc := tmdbusecase.New(cfg.TmdbUrl)
	restInterface := rest.New(addonuc, tmdbUc)
	router := restInterface.SetupRoutes()
	err = http.ListenAndServe(":6969", router)
	if err != nil {
		fmt.Println("Error creating http server ", err)
	}
}
