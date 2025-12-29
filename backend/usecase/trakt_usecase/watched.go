package traktusecase

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	apperrors "zxy/app_errors"
	"zxy/models"
)

func (u *Usecase) getWatchedMovies(token string) ([]models.TraktPlaybackHistoryItem, error) {
	var res []models.TraktPlaybackHistoryItem
	client := http.Client{}
	req, err := http.NewRequest(http.MethodGet, traktUrl+"/sync/watched/movies", nil)
	if err != nil {
		fmt.Println("Error creating get watched movies request ", err)
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", token))
	req.Header.Add("trakt-api-version", "2")
	req.Header.Add("trakt-api-key", u.clientId)
	response, err := client.Do(req)
	if err != nil {
		fmt.Println("Error sending get watched movies request ", err)
		return nil, err
	}
	bodyBytes, err := io.ReadAll(response.Body)
	if err != nil {
		fmt.Println("Error reading get watched movies response body ", err)
		return nil, err
	}

	if response.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code ", response.StatusCode, string(bodyBytes))
		return nil, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(bodyBytes, res)
	if err != nil {
		fmt.Println("Error marshalling get watched movies response body ", err)
		return nil, err
	}

	return res, nil
}

func (u *Usecase) getWatchedSeries(token string) ([]models.TraktPlaybackHistoryItem, error) {
	var res []models.TraktPlaybackHistoryItem
	client := http.Client{}
	req, err := http.NewRequest(http.MethodGet, traktUrl+"/sync/watched/shows", nil)
	if err != nil {
		fmt.Println("Error creating get watched shows request ", err)
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", token))
	req.Header.Add("trakt-api-version", "2")
	req.Header.Add("trakt-api-key", u.clientId)
	response, err := client.Do(req)
	if err != nil {
		fmt.Println("Error sending get watched shows request ", err)
		return nil, err
	}
	bodyBytes, err := io.ReadAll(response.Body)
	if err != nil {
		fmt.Println("Error reading get watched shows response body ", err)
		return nil, err
	}

	if response.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code ", response.StatusCode, string(bodyBytes))
		return nil, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(bodyBytes, res)
	if err != nil {
		fmt.Println("Error marshalling get watched shows response body ", err)
		return nil, err
	}

	return res, nil
}
