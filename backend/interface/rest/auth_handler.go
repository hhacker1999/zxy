package rest

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
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
	fmt.Println(string(data))
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
		ProfileId int `json:"profile_id"`
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
	token, err := i.userUC.LogInProfile(input.ProfileId, userId, sessionId, "")
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
