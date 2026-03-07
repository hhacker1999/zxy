package config

import (
	"fmt"

	"github.com/joho/godotenv"
)

type Config struct {
	TmdbAT              string
	TmdbUrl             string
	TraktUrl            string
	PosgresUrl          string
	MigrationsPath      string
	AIOTemplatePath     string
	AIOInstances        string
	LocalTmdbUrl        string
	ZxyUrl              string
	TraktKey            string
	EncrKey             string
	TraktSecret         string
	RedisAddress        string
	RedisPassword       string
	RedisCacheDb        string
	RedisWatchSessionDb string
	TraktRedirectUri    string
	Port                string
}

func GetConfig(filePath string) (Config, error) {
	configMap, err := godotenv.Read(filePath)
	if err != nil {
		fmt.Println("Error reading config file ", err)
		return Config{}, err
	}
	var config Config
	config.TmdbUrl = configMap["TMDB_URL"]
	config.TraktUrl = configMap["TRAKT_URL"]
	config.TmdbAT = configMap["TMDB_API_KEY"]
	config.PosgresUrl = configMap["POSTGRES_URL"]
	config.LocalTmdbUrl = configMap["LOCAL_TMDB_URL"]
	config.MigrationsPath = configMap["MIGRATIONS_PATH"]
	config.AIOTemplatePath = configMap["AIO_TEMPLATE_PATH"]
	config.AIOInstances = configMap["AIO_INSTANCES"]
	config.TmdbAT = configMap["TMDB_AT"]
	config.ZxyUrl = configMap["ZXY_URL"]
	config.TraktKey = configMap["TRAKT_KEY"]
	config.EncrKey = configMap["ENCR_KEY"]
	config.TraktSecret = configMap["TRAKT_SECRET"]
	config.RedisAddress = configMap["REDIS_ADDR"]
	config.RedisCacheDb = configMap["REDIS_CACHE_DB"]
	config.RedisWatchSessionDb = configMap["REDIS_WATCH_SESSION_DB"]
	config.RedisPassword = configMap["REDIS_PASSWORD"]
	config.TraktRedirectUri = configMap["TRAKT_REDIRECT_URI"]
	config.Port = configMap["PORT"]

	return config, nil
}
