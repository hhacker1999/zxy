package rest

import (
	"encoding/json"
	"io"
	"net/http"
)

func (i *RestInterface) HandleAddSource(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)
	userId := r.Context().Value("user_id").(int)

	type Input struct {
		Value string `json:"value"`
		Type  string `json:"type"`
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


	err = i.addonuc.AddSource(
		userId,
		profileId,
		input.Type,
		input.Value,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}

func (i *RestInterface) HandleRemoveSource(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)
	userId := r.Context().Value("user_id").(int)

	type Input struct {
		Type  string `json:"type"`
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


	err = i.addonuc.RemoveSource(
		userId,
		profileId,
		input.Type,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}
