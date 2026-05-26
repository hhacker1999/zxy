package traktusecase

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
	apperrors "zxy/app_errors"
	"zxy/models"
)

func (u *Usecase) getWatchedMovies(token string) ([]models.TraktPlaybackHistoryItem, error) {
	var res []models.TraktPlaybackHistoryItem
	client := http.Client{}
	req, err := http.NewRequest(http.MethodGet, traktApiUrl+"/sync/watched/movies", nil)
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
	defer response.Body.Close()
	bodyBytes, err := io.ReadAll(response.Body)
	if err != nil {
		fmt.Println("Error reading get watched movies response body ", err)
		return nil, err
	}

	if response.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from trakt", response.StatusCode, string(bodyBytes))
		return nil, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(bodyBytes, &res)
	if err != nil {
		fmt.Println("Error marshalling get watched movies response body ", err)
		return nil, err
	}

	return res, nil
}

func (u *Usecase) getWatchedSeries(token string) ([]models.TraktPlaybackHistoryItem, error) {
	var res []models.TraktPlaybackHistoryItem
	client := http.Client{}
	req, err := http.NewRequest(http.MethodGet, traktApiUrl+"/sync/watched/shows", nil)
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
	defer response.Body.Close()
	bodyBytes, err := io.ReadAll(response.Body)
	if err != nil {
		fmt.Println("Error reading get watched shows response body ", err)
		return nil, err
	}

	if response.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code ", response.StatusCode, string(bodyBytes))
		return nil, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(bodyBytes, &res)
	if err != nil {
		fmt.Println("Error marshalling get watched shows response body ", err)
		return nil, err
	}

	return res, nil
}

func (u *Usecase) getPlayback(token string) ([]models.TraktPlaybackResponeElement, error) {
	var res []models.TraktPlaybackResponeElement
	client := http.Client{}
	req, err := http.NewRequest(http.MethodGet, traktApiUrl+"/sync/playback", nil)
	if err != nil {
		fmt.Println("Error creating get playback request ", err)
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", token))
	req.Header.Add("trakt-api-version", "2")
	req.Header.Add("trakt-api-key", u.clientId)
	response, err := client.Do(req)
	if err != nil {
		fmt.Println("Error sending get playback request ", err)
		return nil, err
	}
	defer response.Body.Close()
	bodyBytes, err := io.ReadAll(response.Body)
	if err != nil {
		fmt.Println("Error reading get get playback response body ", err)
		return nil, err
	}

	if response.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code ", response.StatusCode, string(bodyBytes))
		return nil, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(bodyBytes, &res)
	if err != nil {
		fmt.Println("Error marshalling get playback response body ", err)
		return nil, err
	}

	return res, nil
}

func (u *Usecase) MarkMovieWatched(
	userId int,
	profileId int,
	tmdbId int,
	watchedAt time.Time,
) {
	info, err := u.userRepo.GetUserTraktInfo(userId, profileId)
	if err != nil {
		return
	}
	if !info.IsTraktValid || info.Expiry.Before(time.Now()) {
		fmt.Println("Trakt token is not valid anymore")
		return
	}

	body := map[string]any{
		"movies": []map[string]any{
			{
				"watched_at": watchedAt,
				"ids": map[string]any{
					"tmdb": tmdbId,
				},
			},
		},
	}

	bodyBytes, err := json.Marshal(body)
	if err != nil {
		fmt.Println("Error marhsalling trakt sync history body", err)
		return
	}

	client := http.Client{}
	req, err := http.NewRequest(
		http.MethodPost,
		traktApiUrl+"/sync/history",
		bytes.NewBuffer(bodyBytes),
	)
	if err != nil {
		fmt.Println("Error creating post history request ", err)
		return
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", info.Token))
	req.Header.Add("trakt-api-version", "2")
	req.Header.Add("trakt-api-key", u.clientId)
	response, err := client.Do(req)
	if err != nil {
		fmt.Println("Error sending get playback request ", err)
		return
	}
	defer response.Body.Close()
	bodyBytes, err = io.ReadAll(response.Body)
	if err != nil {
		fmt.Println("Error reading post history response body ", err)
		return
	}

	if response.StatusCode != http.StatusOK && response.StatusCode != 201 {
		if response.StatusCode == http.StatusUnauthorized {
			fmt.Println("User's trakt credentials are expired")
			u.userRepo.SetTraktAuthInvalid(context.Background(), userId, profileId)
			return
		}
		fmt.Println("Invalid status code ", response.StatusCode, string(bodyBytes))
		return
	}
}

func (u *Usecase) MarkSeasonWatched(
	userId int,
	profileId int,
	tmdbId int,
	seasonNo int,
	watchedAt time.Time,
) {
	info, err := u.userRepo.GetUserTraktInfo(userId, profileId)
	if err != nil {
		return
	}
	if !info.IsTraktValid || info.Expiry.Before(time.Now()) {
		fmt.Println("Trakt token is not valid anymore")
		return
	}

	body := map[string]any{
		"shows": []map[string]any{
			{
				"ids": map[string]any{
					"tmdb": tmdbId,
				},
				"seasons": []map[string]any{
					{
						"number":     seasonNo,
						"watched_at": watchedAt,
					},
				},
			},
		},
	}

	bodyBytes, err := json.Marshal(body)
	if err != nil {
		fmt.Println("Error marhsalling trakt sync history body", err)
		return
	}

	client := http.Client{}
	req, err := http.NewRequest(
		http.MethodPost,
		traktApiUrl+"/sync/history",
		bytes.NewBuffer(bodyBytes),
	)
	if err != nil {
		fmt.Println("Error creating post history request ", err)
		return
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", info.Token))
	req.Header.Add("trakt-api-version", "2")
	req.Header.Add("trakt-api-key", u.clientId)
	response, err := client.Do(req)
	if err != nil {
		fmt.Println("Error sending get playback request ", err)
		return
	}
	defer response.Body.Close()
	bodyBytes, err = io.ReadAll(response.Body)
	if err != nil {
		fmt.Println("Error reading get post history response body ", err)
		return
	}

	if response.StatusCode != http.StatusOK && response.StatusCode != 201 {
		if response.StatusCode == http.StatusUnauthorized {
			fmt.Println("User's trakt credentials are expired")
			u.userRepo.SetTraktAuthInvalid(context.Background(), userId, profileId)
			return
		}
		fmt.Println("Invalid status code ", response.StatusCode, string(bodyBytes))
		return
	}
}

func (u *Usecase) MarkEpisodeWatched(
	userId int,
	profileId int,
	tmdbId int,
	seasonNo int,
	episodeNo int,
	watchedAt time.Time,
) {
	info, err := u.userRepo.GetUserTraktInfo(userId, profileId)
	if err != nil {
		return
	}
	fmt.Println(info.IsTraktValid)
	fmt.Println(info.Expiry)
	if !info.IsTraktValid || info.Expiry.Before(time.Now()) {
		fmt.Println("Trakt token is not valid anymore")
		return
	}

	body := map[string]any{
		"shows": []map[string]any{
			{
				"ids": map[string]any{
					"tmdb": tmdbId,
				},
				"seasons": []map[string]any{
					{
						"number": seasonNo,
						"episodes": []map[string]any{
							{
								"number":     episodeNo,
								"watched_at": watchedAt,
							},
						},
					},
				},
			},
		},
	}

	bodyBytes, err := json.Marshal(body)
	if err != nil {
		fmt.Println("Error marhsalling trakt sync history body", err)
		return
	}
	fmt.Println(string(bodyBytes))

	client := http.Client{}
	req, err := http.NewRequest(
		http.MethodPost,
		traktApiUrl+"/sync/history",
		bytes.NewBuffer(bodyBytes),
	)
	if err != nil {
		fmt.Println("Error creating post history request ", err)
		return
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", info.Token))
	req.Header.Add("trakt-api-version", "2")
	req.Header.Add("trakt-api-key", u.clientId)
	response, err := client.Do(req)
	if err != nil {
		fmt.Println("Error sending post history request ", err)
		return
	}
	defer response.Body.Close()
	bodyBytes, err = io.ReadAll(response.Body)
	if err != nil {
		fmt.Println("Error reading post history response body ", err)
		return
	}
	fmt.Println(string(bodyBytes))

	if response.StatusCode != http.StatusOK && response.StatusCode != 201 {
		if response.StatusCode == http.StatusUnauthorized {
			fmt.Println("User's trakt credentials are expired")
			u.userRepo.SetTraktAuthInvalid(context.Background(), userId, profileId)
			return
		}
		fmt.Println("Invalid status code ", response.StatusCode, string(bodyBytes))
		return
	}
}

func (u *Usecase) UpdateProgressTrakt(
	userId int,
	profileId int,
	tmdbId int,
	progress float64,
	isEpisode bool,
) {
	info, err := u.userRepo.GetUserTraktInfo(userId, profileId)
	if err != nil {
		return
	}
	fmt.Println(info.IsTraktValid)
	fmt.Println(info.Expiry)
	if !info.IsTraktValid || info.Expiry.Before(time.Now()) {
		fmt.Println("Trakt token is not valid anymore")
		return
	}

	key := "movie"
	if isEpisode {
		key = "episode"
	}

	body := map[string]any{
		key: map[string]any{
			"ids": map[string]any{
				"tmdb": tmdbId,
			},
		},
		"progress": progress,
	}

	bodyBytes, err := json.Marshal(body)
	if err != nil {
		fmt.Println("Error marshalling trakt sync playback body", err)
		return
	}
	fmt.Println(string(bodyBytes))

	client := http.Client{}
	req, err := http.NewRequest(
		http.MethodPost,
		traktApiUrl+"/scrobble/pause",
		bytes.NewBuffer(bodyBytes),
	)
	if err != nil {
		fmt.Println("Error creating post playback request ", err)
		return
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", info.Token))
	req.Header.Add("trakt-api-version", "2")
	req.Header.Add("trakt-api-key", u.clientId)
	response, err := client.Do(req)
	if err != nil {
		fmt.Println("Error sending post playback request ", err)
		return
	}
	defer response.Body.Close()
	bodyBytes, err = io.ReadAll(response.Body)
	if err != nil {
		fmt.Println("Error reading get get playback response body ", err)
		return
	}

  fmt.Println(string(bodyBytes))
	if response.StatusCode != http.StatusOK && response.StatusCode != 201 {
		if response.StatusCode == http.StatusUnauthorized {
			fmt.Println("User's trakt credentials are expired")
			u.userRepo.SetTraktAuthInvalid(context.Background(), userId, profileId)
			return
		}
		fmt.Println("Invalid status code ", response.StatusCode, string(bodyBytes))
		return
	}
}
