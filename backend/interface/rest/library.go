package rest

import (
	"encoding/json"
	"io"
	"net/http"
)

func (i *RestInterface) HandleAddToLibrary(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)

	type Input struct {
		Type   string `json:"type"`
		TmdbId int    `json:"tmdb_id"`
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

	if input.TmdbId == 0 || (input.Type != "movie" && input.Type != "show") {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid Input"
		return
	}

	err = i.userUC.AddToLibrary(
		profileId,
		input.TmdbId,
		input.Type,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}

func (i *RestInterface) HandleDeleteFromLibrary(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)

	type Input struct {
		Type   string `json:"type"`
		TmdbId int    `json:"tmdb_id"`
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

	if input.TmdbId == 0 || (input.Type != "movie" && input.Type != "show") {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid Input"
		return
	}

	err = i.userUC.RemoveFromLibrary(
		profileId,
		input.TmdbId,
		input.Type,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}

func (i *RestInterface) HandleCheckIfInLibrary(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)

	type Input struct {
		Type   string `json:"type"`
		TmdbId int    `json:"tmdb_id"`
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

	if input.TmdbId == 0 || (input.Type != "movie" && input.Type != "show") {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid Input"
		return
	}

	found, err := i.userUC.UserLibraryCheck(
		profileId,
		input.TmdbId,
		input.Type,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = map[string]bool{
		"found": found,
	}
}
