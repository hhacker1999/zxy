package main

import (
	"fmt"
	"net/http"
	"zxy/interface/rest"
	addonusecase "zxy/usecase/addon_usecase"
	tmdbusecase "zxy/usecase/tmdb_usecase"
)

func main() {
	fmt.Println("Zxy started")
	addonuc := addonusecase.New(
		"http://192.168.1.50:3000/stremio/8f0eb1de-911b-4e0d-92c8-ece4348a7556/eyJpIjoiTUNMN0d4UnFhZjNUVW1ucjlSU2w3UT09IiwiZSI6InVDREt3Y3pEZU5FVW1CR0VLWFNqeFRuTFVkdEV0THNOaDhQbkM0a3Jud289IiwidCI6ImEifQ",
	)
	tmdbUc := tmdbusecase.New("https://api.themoviedb.org/3")
	restInterface := rest.New(addonuc, tmdbUc)
	router := restInterface.SetupRoutes()
	err := http.ListenAndServe(":6969", router)
	if err != nil {
		fmt.Println("Error creating http server ", err)
	}
}
