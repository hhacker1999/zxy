package rest

import (
	"net/http"
)

func (i *RestInterface) HandleGetTraktUrl(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)
	userId := r.Context().Value("user_id").(int)

	url, err := i.traktUC.GetTraktLoginUrl(userId, profileId)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = map[string]string{
		"url": url,
	}
}

func (i *RestInterface) HandleTraktRedirect(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	state := r.URL.Query().Get("state")
	code := r.URL.Query().Get("code")

	err := i.traktUC.RetrieveUserAuthToken(code, state)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}

func (i *RestInterface) HandleTraktDelete(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)
	userId := r.Context().Value("user_id").(int)

	err := i.traktUC.DeleteProfileTraktLogin(userId, profileId)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}
