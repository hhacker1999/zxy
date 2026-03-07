package rest

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"zxy/models"

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

	var details models.TMDBShow
	var err error
	if len(splitted) == 1 {
		details, err = i.tmdbUc.GetShowDetails(
			showId,
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

	genre, err := i.tmdbUc.GetGenres()

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = genre
}

func (i *RestInterface) HandleGetConfiguration(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	config, err := i.tmdbUc.GetConfiguration()

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = config
}

func (i *RestInterface) HandleSearchShows(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	pathParams := r.URL.Query()
	timeLine := pathParams.Get("keyword")
	if len(timeLine) == 0 {
		response.Error = "Keyword cannot be empty"
		response.StatusCode = http.StatusBadRequest
		return
	}

	page := 1
	pageStr := pathParams.Get("page")
	pageInt, err := strconv.Atoi(pageStr)
	if err == nil {
		page = pageInt
	}

	details, err := i.tmdbUc.SearchShows(
		page,
		timeLine,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = details
}

func (i *RestInterface) HandleSearchMovies(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	pathParams := r.URL.Query()
	timeLine := pathParams.Get("keyword")
	if len(timeLine) == 0 {
		response.Error = "Keyword cannot be empty"
		response.StatusCode = http.StatusBadRequest
		return
	}

	page := 1
	pageStr := pathParams.Get("page")
	pageInt, err := strconv.Atoi(pageStr)
	if err == nil {
		page = pageInt
	}

	details, err := i.tmdbUc.SearchMovie(
		page,
		timeLine,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = details
}

func (i *RestInterface) handleLibrary(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	body, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Println("Error reading body")
		res.StatusCode = http.StatusInternalServerError
		res.Error = "Something went wrong"
		return
	}

	defer r.Body.Close()
	var input models.LibraryFilter
	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Println("Error unmarshlling body", err)
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid body"
		return
	}

	data, err := i.tmdbUc.GetLibraryFromFilter(input)
	if err != nil {
		res.StatusCode = http.StatusInternalServerError
		res.Error = err.Error()
		return
	}

	res.StatusCode = http.StatusOK
	res.Data = data
}
