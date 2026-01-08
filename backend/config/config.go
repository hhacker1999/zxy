package config

import (
	"fmt"

	"github.com/joho/godotenv"
)

type Config struct {
	TmdbApiKey     string
	TmdbUrl        string
	TraktUrl       string
	PosgresUrl     string
	MigrationsPath string
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
	config.TmdbApiKey = configMap["TMDB_API_KEY"]
	config.PosgresUrl = configMap["POSTGRES_URL"]
	config.MigrationsPath = configMap["MIGRATIONS_PATH"]

	return config, nil
}
