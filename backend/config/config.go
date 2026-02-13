package config

import (
	"fmt"

	"github.com/joho/godotenv"
)

type Config struct {
	TmdbAT          string
	TmdbUrl         string
	TraktUrl        string
	PosgresUrl      string
	MigrationsPath  string
	AIOTemplatePath string
	AIOInstances    string
	LocalTmdbUrl    string
	ZxyUrl          string
	TraktKey        string
	EncrKey         string
	TraktSecret        string
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

	return config, nil
}
