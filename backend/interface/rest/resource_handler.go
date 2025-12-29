package rest

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
)

func (i *RestInterface) HandleGetMovieInfo(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	movieId := chi.URLParam(r, "id")
	if len(movieId) == 0 {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid movie id"
		return
	}

	details, err := i.tmdbUc.GetMovieDetails(
		movieId,
		"eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU",
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = details
}

func (i *RestInterface) HandleGetShowInfo(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	showId := chi.URLParam(r, "id")
	if len(showId) == 0 {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid show id"
		return
	}
	splitted := strings.Split(showId, ":")
	at := "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU"

	var details []byte
	var err error
	if len(splitted) == 1 {
		details, err = i.tmdbUc.GetShowDetails(
			showId,
			at,
		)
	}

	if len(splitted) == 2 {
		details, err = i.tmdbUc.GetSeasonDetails(
			splitted[0],
			splitted[1],
			at,
		)
	}

	if len(splitted) == 3 {
		details, err = i.tmdbUc.GetEpisodeDetails(
			splitted[0],
			splitted[1],
			splitted[2],
			at,
		)
	}

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = details
}

func (i *RestInterface) HandleGetTrendingMovies(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	pathParams := r.URL.Query()
	timeLine := pathParams.Get("timeline")
	if len(timeLine) == 0 {
		timeLine = "day"
	}

	page := 1
	pageStr := pathParams.Get("page")
	pageInt, err := strconv.Atoi(pageStr)
	if err == nil {
		page = pageInt
	}

	details, err := i.tmdbUc.GetTrendingMovies(
		timeLine,
		page,
		"eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU",
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = details
}

func (i *RestInterface) HandleGetTrendingShows(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	pathParams := r.URL.Query()
	timeLine := pathParams.Get("timeline")
	if len(timeLine) == 0 {
		timeLine = "day"
	}

	page := 1
	pageStr := pathParams.Get("page")
	pageInt, err := strconv.Atoi(pageStr)
	if err == nil {
		page = pageInt
	}

	details, err := i.tmdbUc.GetTrendingShows(
		timeLine,
		page,
		"eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU",
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = details
}

func (i *RestInterface) HandleDiscoverMovies(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	queryParams := r.URL.Query()
	params := make(map[string]string, 0)
	for i, v := range queryParams {
		params[i] = v[0]
	}

	movies, err := i.tmdbUc.GetMovieLibrary(
		params,
		"eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU",
	)

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = movies
}

func (i *RestInterface) HandleDiscoverShows(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	queryParams := r.URL.Query()
	params := make(map[string]string, 0)
	for i, v := range queryParams {
		params[i] = v[0]
	}

	movies, err := i.tmdbUc.GetShowsLibrary(
		params,
		"eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU",
	)

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = movies
}

func (i *RestInterface) HandleGetGenre(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	at := "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU"
	genre, err := i.tmdbUc.GetGenres(
		at,
	)

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = genre
}
