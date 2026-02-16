package rest

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"
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
	var data models.ZxyStreamsRes
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

func (i *RestInterface) handleStream(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	initial := r.URL.Query().Get("internal")
	if len(initial) == 0 {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		res.SendResponse(w)
		return
	}

	plainText, err := i.resolveInternalURL(initial)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		res.SendResponse(w)
		return
	}

	plainText = strings.ReplaceAll(plainText, "comet:8000", "10.8.0.1:2020")

	req, err := http.NewRequest("HEAD", plainText, nil)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		res.SendResponse(w)
		return
	}

	// req.Header.Set("Range", "bytes=0-0")
	fmt.Println("Got url ", plainText)

	resp, err := i.client.Do(req)
	if err != nil {
		if res.StatusCode == http.StatusMethodNotAllowed {
			http.Redirect(w, r, resp.Request.URL.String(), http.StatusFound)
			return
		}
		res.StatusCode = http.StatusBadGateway
		res.Error = "Source resolution failed"
		res.SendResponse(w)
		return
	}
	defer resp.Body.Close()

	finalURL := resp.Request.URL.String()
	fmt.Println("Final url ", finalURL)

	http.Redirect(w, r, finalURL, http.StatusFound)
}

func (i *RestInterface) handleProxy(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	initial := r.URL.Query().Get("internal")
	if len(initial) == 0 {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		res.SendResponse(w)
		return
	}

	url, err := i.resolveInternalURL(initial)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		res.SendResponse(w)
		return
	}
	client := &http.Client{
		Timeout: 5 * time.Second,
	}

	resp, err := client.Head(url)
	if err != nil {
		res.StatusCode = http.StatusBadGateway
		res.Error = "Source resolution failed"
		res.SendResponse(w)
		return
	}
	defer resp.Body.Close()
	finalURL := resp.Request.URL.String()
	ctx := context.WithValue(r.Context(), "url", finalURL)

	i.proxy.ServeHTTP(w, r.WithContext(ctx))
}

func (i *RestInterface) resolveInternalURL(initial string) (string, error) {
	ciphertext, err := hex.DecodeString(initial)
	if err != nil {
		fmt.Println("Error decoding hex", err)
		return "", err
	}
	key, err := hex.DecodeString(i.encrKey)
	if err != nil {
		return "", err
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		fmt.Println("Error creating new cipher", err)
		return "", err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		fmt.Println("Error in new gcm", err)
		return "", err
	}

	nonceSize := gcm.NonceSize()
	nonce, actualCiphertext := ciphertext[:nonceSize], ciphertext[nonceSize:]

	plainText, err := gcm.Open(nil, nonce, actualCiphertext, nil)
	if err != nil {
		return "", err
	}
	return string(plainText), nil
}
