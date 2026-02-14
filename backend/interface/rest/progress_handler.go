package rest

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
)

func (i *RestInterface) HandleGetContinueWatching(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)

	// at := "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU"

	data, err := i.progressUC.GetContinueWatching(userId, profileId)

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = data
}

func (i *RestInterface) HandleMovieProgressUpdate(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)

	type Input struct {
		MovieId  string  `json:"movie_id"`
		Progress float64 `json:"progress"`
	}

	bodyBytes, err := io.ReadAll(r.Body)
	if err != nil {
		response.StatusCode = http.StatusInternalServerError
		response.Error = "Something went wrong"
		return
	}

	defer r.Body.Close()
	var input Input
	err = json.Unmarshal(bodyBytes, &input)
	if err != nil {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid Input"
		return
	}

	err = i.progressUC.UpdatePlaybackProgress(
		userId,
		profileId,
		input.MovieId,
		input.Progress,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}

func (i *RestInterface) HandleShowProgressUpdate(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)

	type Input struct {
		ShowId   string  `json:"show_id"`
		Progress float64 `json:"progress"`
		Season   int     `json:"season"`
		Episode  int     `json:"episode"`
	}

	bodyBytes, err := io.ReadAll(r.Body)
	if err != nil {
		response.StatusCode = http.StatusInternalServerError
		response.Error = "Something went wrong"
		return
	}

	defer r.Body.Close()
	var input Input
	err = json.Unmarshal(bodyBytes, &input)
	if err != nil {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid Input"
		return
	}

	if input.Season == 0 {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid Season"
		return
	}

	if input.Episode == 0 {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid Episode"
		return
	}

	err = i.progressUC.UpdatePlaybackProgress(
		userId,
		profileId,
		fmt.Sprintf("%s:%d:%d", input.ShowId, input.Season, input.Episode),
		input.Progress,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}

func (i *RestInterface) HandleGetShowProgress(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)

	showId := chi.URLParam(r, "id")
	if len(showId) == 0 {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid show id"
		return
	}

	// at := "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU"

	data, err := i.progressUC.GetShowProgress(userId, profileId, showId)

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = data
}

func (i *RestInterface) HandleGetMovieProgress(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)

	movieId := chi.URLParam(r, "id")
	if len(movieId) == 0 {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid show id"
		return
	}

	// at := "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU"

	data, err := i.progressUC.GetMovieProgress(userId, profileId, movieId)

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = data
}

func (i *RestInterface) handleMovieWatched(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)

	movieId := chi.URLParam(r, "id")
	if len(movieId) == 0 {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid id"
		return
	}

	err := i.progressUC.MarkMovieWatched(userId, profileId, movieId)
	if err != nil {
		res.StatusCode = http.StatusInternalServerError
		res.Error = err.Error()
		return
	}

	res.StatusCode = http.StatusOK
}

func (i *RestInterface) handleShowWatched(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)

	id := chi.URLParam(r, "id")
	if len(id) == 0 {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid id"
		return
	}
	splitted := strings.Split(id, ":")
	var err error
	if len(splitted) == 1 {
		err = i.progressUC.MarkShowWatched(userId, profileId, id)
	} else if len(splitted) == 2 {
		season, err := strconv.Atoi(splitted[1])
		if err != nil {
			res.StatusCode = http.StatusBadRequest
			res.Error = "Invalid season"
			return
		}
		err = i.progressUC.MarkSeasonWatched(userId, profileId, splitted[0], season)
	} else {
		season, err := strconv.Atoi(splitted[1])
		if err != nil {
			res.StatusCode = http.StatusBadRequest
			res.Error = "Invalid season"
			return
		}
		episode, err := strconv.Atoi(splitted[2])
		if err != nil {
			res.StatusCode = http.StatusBadRequest
			res.Error = "Invalid episode"
			return
		}
		err = i.progressUC.MarkEpisodeWatched(userId, profileId, splitted[0], season, episode)
	}

	if err != nil {
		res.StatusCode = http.StatusInternalServerError
		res.Error = err.Error()
		return
	}

	res.StatusCode = http.StatusOK
}

func (i *RestInterface) handleDeleteContinueWatching(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)

	id := chi.URLParam(r, "id")
	if len(id) == 0 {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid id"
		return
	}

	err := i.progressUC.RemoveFromContinueWatching(userId, profileId, id)
	if err != nil {
		res.StatusCode = http.StatusInternalServerError
		res.Error = err.Error()
		return
	}

	res.StatusCode = http.StatusOK
}
