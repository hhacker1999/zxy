package rest

import (
	"net/http"
	"strconv"
	"zxy/models"
)

func (i *RestInterface) HandleGetStream(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

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
	var data []models.AddonStream
  var err error

	if streamType == "series" {
		season := params.Get("season")
		if len(season) == 0 {
			response.Error = "Invalid season"
			response.StatusCode = http.StatusBadRequest
			return
		}
		seasonInt, err := strconv.Atoi(season)
		if err != nil {
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
		episodeInt, err := strconv.Atoi(episode)
		if err != nil {
			response.Error = "Invalid episode"
			response.StatusCode = http.StatusBadRequest
			return
		}
		data, err = i.addonuc.GetSeriesStream(id, seasonInt, episodeInt)
	} else {
		data, err = i.addonuc.GetMovieStream(id)
	}

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = data
}

