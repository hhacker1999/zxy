package rest

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"
	"zxy/models"
)

func (i *RestInterface) HandleGetStream(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)

	params := r.URL.Query()
	streamType := params.Get("type")
	if len(streamType) == 0 || (streamType != "movie" && streamType != "series") {
		response.Error = "Invalid stream type"
		response.StatusCode = http.StatusBadRequest
		return
	}
	id := params.Get("id")
	if len(id) == 0 {
		response.Error = "Invalid id"
		response.StatusCode = http.StatusBadRequest
		return
	}
	var data []models.StreamResult
	var err error

	if streamType == "series" {
		season := params.Get("season")
		if len(season) == 0 {
			response.Error = "Invalid season"
			response.StatusCode = http.StatusBadRequest
			return
		}
		seasonInt, errr := strconv.Atoi(season)
		if errr != nil {
			response.Error = "Invalid season"
			response.StatusCode = http.StatusBadRequest
			return
		}

		episode := params.Get("episode")
		if len(episode) == 0 {
			response.Error = "Invalid episode"
			response.StatusCode = http.StatusBadRequest
			return
		}
		episodeInt, errr := strconv.Atoi(episode)
		if errr != nil {
			response.Error = "Invalid episode"
			response.StatusCode = http.StatusBadRequest
			return
		}
		data, err = i.addonuc.GetSeriesStreamProfile(id, seasonInt, episodeInt, profileId)
	} else {
		data, err = i.addonuc.GetMovieStreamProfile(id, profileId)
	}

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = data
}

func (i *RestInterface) HandleAddDebridKey(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)
	userId := r.Context().Value("user_id").(int)

	type Input struct {
		ApiKey     string `json:"api_key"`
		DebridType string `json:"debrid_type"`
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

	if input.ApiKey == "" {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid type"
		return
	}

	if input.DebridType != "rd" && input.DebridType != "tb" {
		response.StatusCode = http.StatusBadRequest
		response.Error = "Invalid type"
		return
	}

	err = i.addonuc.StoreAddonFromApiKey(
		userId,
		profileId,
		input.ApiKey,
		input.DebridType,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}

func (i *RestInterface) HandleRemoveDebridKey(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)
	userId := r.Context().Value("user_id").(int)

	err := i.addonuc.RemoveDebridKey(
		userId,
		profileId,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}
