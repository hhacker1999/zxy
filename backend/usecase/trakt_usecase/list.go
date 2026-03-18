package traktusecase

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	apperrors "zxy/app_errors"
	"zxy/models"
)

func (u *Usecase) GetLikedLists(userId int, profileId int) ([]models.TraktLikedList, error) {
	var res []models.TraktLikedList
	details, err := u.userRepo.GetUserTraktInfo(userId, profileId)
	if err != nil {
		return nil, apperrors.SomethingWentWrongError{}
	}

	req, err := http.NewRequest(
		http.MethodGet,
		fmt.Sprintf("%s/users/%s/likes/lists", traktApiUrl, details.User.IDS.Slug),
		nil,
	)
	if err != nil {
		fmt.Println("Error creating user liked list request", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	httpRes, err := u.doTraktPrivateReq(req, details.Token)
	defer httpRes.Body.Close()

	if err != nil {
		fmt.Println("Error doing trakt liked list request", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	resBody, err := io.ReadAll(httpRes.Body)
	if err != nil {
		fmt.Println("Error reading trakt liked list response body", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if httpRes.StatusCode != http.StatusOK {
		fmt.Println(string(resBody))
		fmt.Println("Invalid status code from trakt", httpRes.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(resBody, &res)
	if err != nil {
		fmt.Println("Error unmarshalling trakt liked list response", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return res, nil
}

func (u *Usecase) GetUsersLists(userId int, profileId int) ([]models.TraktList, error) {
	var res []models.TraktList
	details, err := u.userRepo.GetUserTraktInfo(userId, profileId)
	if err != nil {
		return nil, apperrors.SomethingWentWrongError{}
	}

	req, err := http.NewRequest(
		http.MethodGet,
		fmt.Sprintf("%s/users/%s/lists", traktApiUrl, details.User.IDS.Slug),
		nil,
	)
	if err != nil {
		fmt.Println("Error creating user list request", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	httpRes, err := u.doTraktPrivateReq(req, details.Token)
	defer httpRes.Body.Close()

	if err != nil {
		fmt.Println("Error doing trakt list request", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	resBody, err := io.ReadAll(httpRes.Body)
	if err != nil {
		fmt.Println("Error reading trakt list response body", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if httpRes.StatusCode != http.StatusOK {
		fmt.Println(string(resBody))
		fmt.Println("Invalid status code from trakt", httpRes.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(resBody, &res)
	if err != nil {
		fmt.Println("Error unmarshalling trakt list response", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return res, nil
}
