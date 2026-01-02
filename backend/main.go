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
		"https://aiostreamsfortheweak.nhyira.dev/stremio/02072089-005e-4b86-9103-38dbac2d794c/eyJpIjoiYS9QcnNZbldNMU5QY1IrODF5dGswdz09IiwiZSI6InE4c2pQKzQrNkdVUmN2aDFJTC9GK0E2eVZseG1ORTliYnN3M290VU9jQm89IiwidCI6ImEifQ",
	)
	tmdbUc := tmdbusecase.New("https://api.themoviedb.org/3")
	restInterface := rest.New(addonuc, tmdbUc)
	router := restInterface.SetupRoutes()
	err := http.ListenAndServe(":6969", router)
	if err != nil {
		fmt.Println("Error creating http server ", err)
	}
}
