package rest

import (
	addonusecase "zxy/usecase/addon_usecase"
	tmdbusecase "zxy/usecase/tmdb_usecase"

	"github.com/go-chi/chi/v5"
)

type RestInterface struct {
	addonuc *addonusecase.Usecase
	tmdbUc  *tmdbusecase.Usecase
}

func New(addonuc *addonusecase.Usecase, tmdbUc *tmdbusecase.Usecase) *RestInterface {
	return &RestInterface{
		addonuc: addonuc,
		tmdbUc:  tmdbUc,
	}
}

func (i *RestInterface) SetupRoutes() *chi.Mux {
	router := chi.NewRouter()
	router.Post("/signup", i.handleSignup)
	router.Get("/streams", i.HandleGetStream)
	router.Get("/discover/movies", i.HandleDiscoverMovies)
	router.Get("/discover/shows", i.HandleDiscoverShows)
	router.Get("/trending/movies", i.HandleGetTrendingMovies)
	router.Get("/trending/shows", i.HandleGetTrendingShows)
	router.Get("/search/show", i.HandleSearchShows)
	router.Get("/search/movie", i.HandleSearchMovies)
	router.Get("/movie/{id}", i.HandleGetMovieInfo)
	router.Get("/show/{id}", i.HandleGetShowInfo)
	router.Get("/genre", i.HandleGetGenre)
	router.Get("/configuration", i.HandleGetConfiguration)
	return router
}
