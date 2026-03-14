package addonusecase

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	apperrors "zxy/app_errors"
	"zxy/models"
)

func (u *Usecase) GetMovieStreamZxy(
	id string,
	userId int,
	profileId int,
	userIp string,
) (models.ZxyStreamsRes, error) {
	var res models.ZxyStreamsRes
	var aioRes models.AddonStreamResponse

	profile, err := u.userRepo.GetUserProfile(context.Background(), userId, profileId)
	if err != nil {
		return res, err
	}
	debrid := "realdebrid"
	if profile.DebridType == "tb" {
		debrid = "torbox"
	}
	key := profile.DebridKey
	if len(key) == 0 {
		return res, apperrors.InvalidInput{Err: "Add debrid key first"}
	}
	reqBody, err := json.Marshal(map[string]any{
		"services": []map[string]any{
			{
				"id":      debrid,
				"enabled": true,
				"credentials": map[string]any{
					"apiKey": key,
				},
			},
		},
	})
	if err != nil {
		fmt.Println("Error marshalling request body", err)
		return res, apperrors.SomethingWentWrongError{}
	}
	url :=
		fmt.Sprintf(
			"%s/zxy/streams/movie/%s?uid=%s&pwd=%s",
			u.zxyAioInstance,
			id,
			u.zxyAioUid,
			u.zxyAioPwd,
		)

	req, err := http.NewRequest(
		http.MethodPost,
		url,
		bytes.NewBuffer(reqBody),
	)
	if err != nil {
		fmt.Println("Error creating movie stream request ", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	req.Header.Set("X-Forwarded-For", userIp)
	req.Header.Set("X-Real-IP", userIp)
	req.Header.Set("X-Client-Ip", userIp)
	req.Header.Set("Content-Type", "application/json")

	addonResponse, err := http.DefaultClient.Do(
		req,
	)
	if err != nil {
		fmt.Println("Error sending movie stream request ", err)
		return res, apperrors.SomethingWentWrongError{}
	}
	defer addonResponse.Body.Close()

	bodyBytes, err := io.ReadAll(addonResponse.Body)
	if err != nil {
		fmt.Println("Error reading movie stream response ", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	if addonResponse.StatusCode != http.StatusOK {
		fmt.Println(
			"Invalid status code movie stream request ",
			addonResponse.StatusCode,
			string(bodyBytes),
		)
		return res, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(bodyBytes, &aioRes)
	if err != nil {
		fmt.Println("Error unmarshalling movie stream response ", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	return u.getResponseStreamFromAioStream(aioRes)
}

func (u *Usecase) GetSeriesStreamZxy(
	id string,
	season int,
	episode int,
	userId int,
	profileId int,
	userIp string,
) (models.ZxyStreamsRes, error) {
	var res models.ZxyStreamsRes
	var aioRes models.AddonStreamResponse

	profile, err := u.userRepo.GetUserProfile(context.Background(), userId, profileId)
	if err != nil {
		return res, err
	}
	debrid := "realdebrid"
	if profile.DebridType == "tb" {
		debrid = "torbox"
	}
	key := profile.DebridKey
	if len(key) == 0 {
		return res, apperrors.InvalidInput{Err: "Add debrid key first"}
	}

	reqBody, err := json.Marshal(map[string]any{
		"services": []map[string]any{
			{
				"id":      debrid,
				"enabled": true,
				"credentials": map[string]any{
					"apiKey": key,
				},
			},
		},
	})
	if err != nil {
		fmt.Println("Error marshalling request body", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	req, err := http.NewRequest(
		http.MethodPost,
		fmt.Sprintf(
			"%s/zxy/streams/series/%s:%d:%d?uid=%s&pwd=%s",
			u.zxyAioInstance,
			id,
			season,
			episode,
			u.zxyAioUid,
			u.zxyAioPwd,
		),
		bytes.NewBuffer(reqBody),
	)
	if err != nil {
		fmt.Println("Error creating movie stream request ", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	req.Header.Set("X-Forwarded-For", userIp)
	req.Header.Set("X-Real-IP", userIp)
	req.Header.Set("X-Client-Ip", userIp)
	req.Header.Set("Content-Type", "application/json")

	addonResponse, err := http.DefaultClient.Do(
		req,
	)
	if err != nil {
		fmt.Println("Error sending series stream request ", err)
		return res, apperrors.SomethingWentWrongError{}
	}
	defer addonResponse.Body.Close()

	bodyBytes, err := io.ReadAll(addonResponse.Body)
	if err != nil {
		fmt.Println("Error reading series stream response ", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	if addonResponse.StatusCode != http.StatusOK {
		fmt.Println(
			"Invalid status code series stream request ",
			addonResponse.StatusCode,
			string(bodyBytes),
		)
		return res, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(bodyBytes, &aioRes)
	if err != nil {
		fmt.Println("Error unmarshalling series stream response ", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	return u.getResponseStreamFromAioStream(aioRes)
}

func (u *Usecase) getResponseStreamFromAioStream(
	aioRes models.AddonStreamResponse,
) (models.ZxyStreamsRes, error) {
	var res models.ZxyStreamsRes

	uhd := []models.ZxyResolutionResponse{}
	fhd := []models.ZxyResolutionResponse{}
	hd := []models.ZxyResolutionResponse{}

	for _, v := range aioRes.Streams {
		if v.URL == "" {
			continue
		}
		mp := make(map[string]any)
		err := json.Unmarshal([]byte(v.Name), &mp)
		if err != nil {
			fmt.Println("Error unmarshalling stream name", err)
		}

		var temp models.ZxyResolutionResponse
		temp.VisualTags = v.StreamData.ParsedFile.VisualTags
		temp.AudioTags = v.StreamData.ParsedFile.AudioTags
		temp.FileName = v.BehaviorHints.Filename
		temp.Quality = v.StreamData.ParsedFile.Quality
		temp.Size = int(v.StreamData.Size)

		encrypted, err := u.encryptURL(v.URL)
		if err != nil {
			fmt.Println("Error getting encrypted url", err)
			return res, apperrors.SomethingWentWrongError{}
		}
		temp.Url = fmt.Sprintf(
			"%s/stream?internal=%s",
			u.zxyUrl,
			encrypted,
		)
		temp.Resolution = v.StreamData.ParsedFile.Resolution
		if temp.Resolution == "2160p" {
			uhd = append(uhd, temp)
		} else if temp.Resolution == "1080p" {
			fhd = append(fhd, temp)
		} else if temp.Resolution == "720p" {
			hd = append(hd, temp)
		} else {
			fmt.Println("resolution not found")
		}
		temp.Name = v.Name
		temp.Description = v.Description
	}

	res.UHD = uhd
	res.FHD = fhd
	res.HD = hd

	return res, nil
}
