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
		"https://aiostreamsfortheweebs.midnightignite.me/stremio/e8aeec76-d976-4cfd-8a03-ffc6c9622d2b/eyJpIjoiUDVXc3p6M0dpSnQvWS96MEFvQlpvZz09IiwiZSI6IjRTZXZ6OW5RaXpqR0lXSFpPeUlNOVE9PSIsInQiOiJhIn0",
	)
	tmdbUc := tmdbusecase.New("https://api.themoviedb.org/3")
	restInterface := rest.New(addonuc, tmdbUc)
	router := restInterface.SetupRoutes()
	err := http.ListenAndServe(":6969", router)
	if err != nil {
		fmt.Println("Error creating http server ", err)
	}
}
