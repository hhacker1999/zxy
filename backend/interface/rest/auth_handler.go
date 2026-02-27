package rest

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"zxy/models"
	userusecase "zxy/usecase/user_usecase"
)

func (i *RestInterface) handleSignup(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	data, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Println("Error reading request body", err)
		res.StatusCode = http.StatusInternalServerError
		return
	}
	defer r.Body.Close()
	type Input struct {
		Email    string `json:"email"`
		Password string `json:"password"`
		Name     string `json:"name"`
	}
	var input Input
	err = json.Unmarshal(data, &input)
	if err != nil {
		fmt.Println("Error unmarshalling request body", err)
		res.StatusCode = http.StatusInternalServerError
		return
	}
	err = i.userUC.Signup(input.Name, input.Email, input.Password)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = err.Error()
		return
	}
	res.StatusCode = http.StatusOK
	res.Data = map[string]string{
		"message": "User registered successfully",
	}
}

func (i *RestInterface) handleLogin(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	data, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Println("Error reading request body", err)
		res.StatusCode = http.StatusInternalServerError
		res.Error = "Internal server error"
		return
	}
	defer r.Body.Close()
	type Input struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	var input Input
	err = json.Unmarshal(data, &input)
	if err != nil {
		fmt.Println("Error unmarshalling request body", err)
		res.StatusCode = http.StatusInternalServerError
		res.Error = "Internal server error"
		return
	}
	user, token, err := i.userUC.LogInUser(input.Email, input.Password)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = err.Error()
		return
	}
	cookie := &http.Cookie{
		Name:     "session_token",
		Value:    token,
		HttpOnly: true,
		Path:     "/",
	}
	http.SetCookie(w, cookie)
	res.StatusCode = http.StatusOK
	res.Data = user
}

func (i *RestInterface) handleProfileLogin(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	data, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Println("Error reading request body", err)
		res.StatusCode = http.StatusInternalServerError
		return
	}
	defer r.Body.Close()
	type Input struct {
		ProfileId int    `json:"profile_id"`
		Pin       string `json:"pin"`
	}
	var input Input
	err = json.Unmarshal(data, &input)
	if err != nil {
		fmt.Println("Error unmarshalling request body", err)
		res.StatusCode = http.StatusInternalServerError
		return
	}
	sessionId := r.Context().Value("session_id").(int)
	userId := r.Context().Value("user_id").(int)
	token, err := i.userUC.LogInProfile(input.ProfileId, userId, sessionId, input.Pin)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = err.Error()
		return
	}

	cookie := &http.Cookie{
		Name:     "profile_token",
		Value:    token,
		HttpOnly: true,
		Path:     "/",
	}
	http.SetCookie(w, cookie)
	res.StatusCode = http.StatusOK
	res.Data = map[string]string{
		"message": "Profile logged in successfully",
	}
}

func (i *RestInterface) handleGetUser(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	user, err := i.userUC.GetUser(userId)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = err.Error()
		return
	}
	res.StatusCode = http.StatusOK
	res.Data = user
}

func (i *RestInterface) handleGetUserProfile(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)
	profile, err := i.userUC.GetUserProfile(userId, profileId)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = err.Error()
		return
	}
	res.StatusCode = http.StatusOK
	res.Data = profile
}

func (i *RestInterface) handleCreateUserProfile(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)
	body, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Println("Error reading request body", err)
		res.Error = "Something went wrong"
		res.StatusCode = http.StatusInternalServerError
		return
	}
	defer r.Body.Close()

	input := userusecase.CreateProfileInput{
		UserId:           userId,
		CreaterProfileId: profileId,
	}
	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Println("Error unmarshalling req body", err)
		res.Error = "Invalid body"
		res.StatusCode = http.StatusBadRequest
		return
	}

	err = i.userUC.CreateUserProfile(input)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = err.Error()
		return
	}
	res.StatusCode = http.StatusOK
}

func (i *RestInterface) handleUpdateUserProfile(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)
	body, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Println("Error reading request body", err)
		res.Error = "Something went wrong"
		res.StatusCode = http.StatusInternalServerError
		return
	}
	defer r.Body.Close()

	input := userusecase.CreateProfileInput{
		UserId:           userId,
		CreaterProfileId: profileId,
	}
	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Println("Error unmarshalling req body", err)
		res.Error = "Invalid body"
		res.StatusCode = http.StatusBadRequest
		return
	}

	err = i.userUC.UpdateUserProfile(input)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = err.Error()
		return
	}
	res.StatusCode = http.StatusOK
}

func (i *RestInterface) handleDeleteUserProfile(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)
	profileToDeleteStr := r.URL.Query().Get("profile_id")
	profileToDelete, err := strconv.Atoi(profileToDeleteStr)
	if len(profileToDeleteStr) == 0 || err != nil {
		res.Error = "Invalid profile id "
		res.StatusCode = http.StatusBadRequest
		return
	}

	err = i.userUC.DeleteUserProfile(userId, profileToDelete, profileId)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = err.Error()
		return
	}
	res.StatusCode = http.StatusOK
}

func (i *RestInterface) handleUpdateUserProfileLists(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)
	body, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Println("Error reading request body", err)
		res.Error = "Something went wrong"
		res.StatusCode = http.StatusInternalServerError
		return
	}
	defer r.Body.Close()

	var input []models.ProfileLibraryItem

	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Println("Error unmarshalling req body", err)
		res.Error = "Invalid body"
		res.StatusCode = http.StatusBadRequest
		return
	}

	err = i.userUC.UpdateProfileList(userId, profileId, input)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = err.Error()
		return
	}
	res.StatusCode = http.StatusOK
}

func (i *RestInterface) handleDeleteUser(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)

	err := i.userUC.DeleteAccount(userId, profileId)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = err.Error()
		return
	}
	res.StatusCode = http.StatusOK
}
