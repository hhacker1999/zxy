package rest

import (
	"encoding/json"
	"io"
	"net/http"
)

func (i *RestInterface) HandleAddAddon(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)
	userId := r.Context().Value("user_id").(int)

	type Input struct {
		ManifestUrl string `json:"manifest_url"`
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

	err = i.addonuc.AddStreamioAddon(
		userId,
		profileId,
		input.ManifestUrl,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}

func (i *RestInterface) HandleRemoveAddon(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)

	type Input struct {
		AddonId int `json:"addon_id"`
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

	err = i.addonuc.RemoveStreamioAddon(
		profileId,
		input.AddonId,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}

func (i *RestInterface) HandleEnableAddon(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)

	type Input struct {
		AddonId int `json:"addon_id"`
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

	err = i.addonuc.UpdateStreamioAddon(
		profileId,
		input.AddonId,
		true,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}

func (i *RestInterface) HandleDisableAddon(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)

	type Input struct {
		AddonId int `json:"addon_id"`
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

	err = i.addonuc.UpdateStreamioAddon(
		profileId,
		input.AddonId,
		false,
	)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}
