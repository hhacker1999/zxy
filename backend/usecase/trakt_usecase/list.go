package traktusecase

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
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

func (u *Usecase) GetUsersRecommendations(
	userId int,
	profileId int,
	filter models.LibraryFilter,
) ([]models.Item, int, error) {
	var res []models.Item
	details, err := u.userRepo.GetUserTraktInfo(userId, profileId)
	if err != nil {
		return nil, 0, apperrors.SomethingWentWrongError{}
	}

	tp := "shows"
	if filter.IsMovie {
		tp = "movies"
	}
	url := fmt.Sprintf(
		"%s/recommendations/%s?page=%d&limit=%d",
		traktApiUrl,
		tp,
		filter.Page,
		filter.Items,
	)

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		fmt.Println("Error creating trakt recommended request", err)
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	httpRes, err := u.doTraktPrivateReq(req, details.Token)
	defer httpRes.Body.Close()

	if err != nil {
		fmt.Println("Error doing trakt list request", err)
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	resBody, err := io.ReadAll(httpRes.Body)
	if err != nil {
		fmt.Println("Error reading trakt list response body", err)
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	if httpRes.StatusCode != http.StatusOK {
		fmt.Println(string(resBody))
		fmt.Println("Invalid status code from trakt", httpRes.StatusCode)
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	count, err := strconv.Atoi(httpRes.Header.Get("X-Pagination-Item-Count"))
	if err != nil {
		fmt.Println("Invalid total items trakt", err)
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(resBody, &res)
	if err != nil {
		fmt.Println("Error unmarshalling trakt list response", err)
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	return res, count, nil
}

func (u *Usecase) GetUsersListItems(
	userId int,
	profileId int,
	filter models.LibraryFilter,
) ([]models.TraktMultiMediaResponseElement, int, error) {
	var res []models.TraktMultiMediaResponseElement
	details, err := u.userRepo.GetUserTraktInfo(userId, profileId)
	if err != nil {
		return nil, 0, apperrors.SomethingWentWrongError{}
	}

	url := fmt.Sprintf(
		"%s/lists/%s/items?page=%d&limit=%d",
		traktApiUrl,
		filter.TraktId,
		filter.Page,
		filter.Items,
	)

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		fmt.Println("Error creating trakt list request", err)
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	httpRes, err := u.doTraktPrivateReq(req, details.Token)

	if err != nil {
		fmt.Println("Error doing trakt list request", err)
		return res, 0, apperrors.SomethingWentWrongError{}
	}
	defer httpRes.Body.Close()

	resBody, err := io.ReadAll(httpRes.Body)
	if err != nil {
		fmt.Println("Error reading trakt list response body", err)
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	if httpRes.StatusCode != http.StatusOK {
		fmt.Println(string(resBody))
		fmt.Println("Invalid status code from trakt", httpRes.StatusCode)
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	count, err := strconv.Atoi(httpRes.Header.Get("X-Pagination-Item-Count"))
	if err != nil {
		fmt.Println("Invalid total items trakt", err)
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(resBody, &res)
	if err != nil {
		fmt.Println("Error unmarshalling trakt list response", err)
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	return res, count, nil
}
