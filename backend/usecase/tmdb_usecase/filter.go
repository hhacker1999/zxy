package tmdbusecase

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"
	apperrors "zxy/app_errors"
	"zxy/models"
)

func (u *Usecase) GetLibraryFromFilter(
	userId int, profileId int,
	filter models.LibraryFilter,
) (any, error) {
	// NOTE: We are using trakt to get trending things
	var data []models.ZxyMedia
	var items int
	var err error
	if filter.Type == models.TRAKT {
		if filter.TraktId == models.TRENDING {
			return u.GetTrending(filter)
		} else if filter.TraktId == models.RECOMMENDED {
			data, items, err = u.getTraktRecommendations(userId, profileId, filter)
			if err != nil {
				u.userRepo.SetTraktAuthInvalid(context.Background(), userId, profileId)
				return nil, err
			}
		} else {
			data, items, err = u.getTraktUserListItems(userId, profileId, filter)
			if err != nil {
				u.userRepo.SetTraktAuthInvalid(context.Background(), userId, profileId)
				return nil, err
			}
		}
	} else if filter.Type == models.LIBRARY {
		data, items, err = u.getUserLibraryItems(profileId, filter)
	} else {
		data, items, err = u.localTmdbRepo.GetLibrary(filter)
	}

	if err != nil {
		return nil, apperrors.SomethingWentWrongError{}
	}
	var res models.MediaPaginatedResponse
	res.Results = data
	res.TotalResults = items
	res.TotalPages = (items + filter.Items - 1) / len(data)
	res.Page = filter.Page
	if res.Page == 0 {
		res.Page = 1
	}

	return res, nil
}
func (u *Usecase) GetTrending(filter models.LibraryFilter) ([]byte, error) {
	tp := "shows"
	if filter.IsMovie {
		tp = "movies"
	}
	key := fmt.Sprintf("%s:%d:%d", tp, filter.Page, filter.Items)
	bodyBytes, err := u.redisCacheDb.Get(context.Background(), key).Result()
	if err != nil {
		response, err := u.getTrendingInternal(filter)
		if err != nil {
			return nil, err
		}
		resBytes, err := json.Marshal(response)
		if err != nil {
			fmt.Println("Error marshalling trending response", err)
			return nil, apperrors.SomethingWentWrongError{}
		}
		go u.redisCacheDb.Set(
			context.Background(),
			key,
			string(resBytes),
			time.Duration(time.Minute*30),
		)
		return resBytes, nil
	}
	return []byte(bodyBytes), nil
}

func (u *Usecase) getTrendingInternal(
	filter models.LibraryFilter,
) (models.MediaPaginatedResponse, error) {
	var res models.MediaPaginatedResponse
	tp := "shows"
	if filter.IsMovie {
		tp = "movies"
	}
	url := fmt.Sprintf(
		"https://api.trakt.tv/%s/trending?page=%d&limit=%d",
		tp,
		filter.Page,
		filter.Items,
	)

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		fmt.Println("Error creating trakt trending request", err)
		return res, apperrors.SomethingWentWrongError{}
	}
	req.Header.Add("trakt-api-version", "2")
	req.Header.Add("trakt-api-key", u.traktKey)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending trakt trending request", err)
		return res, apperrors.SomethingWentWrongError{}
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("Error reading trakt trending response", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	fmt.Println(string(body))
	if resp.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from trakt", resp.StatusCode)
		fmt.Println(string(body))
		return res, apperrors.SomethingWentWrongError{}
	}

	var temp []models.TraktMultiMediaResponseElement
	err = json.Unmarshal(body, &temp)
	if err != nil {
		fmt.Println("Error unmarshalling trakt trending response", err)
		return res, apperrors.SomethingWentWrongError{}
	}
	var ids []int
	for _, v := range temp {
		if filter.IsMovie {
			ids = append(ids, int(v.Movie.IDS.Tmdb))
		} else {
			ids = append(ids, int(v.Show.IDS.Tmdb))
		}
	}

	tp = "show"
	if filter.IsMovie {
		tp = "movie"
	}

	media, err := u.localTmdbRepo.GetLibraryFromIdsSameOrder(ids, tp)
	if err != nil {
		return res, err
	}
	count, err := strconv.Atoi(resp.Header.Get("X-Pagination-Page-Count"))
	if err == nil {
		res.TotalPages = count
	}
	count, err = strconv.Atoi(resp.Header.Get("X-Pagination-Item-Count"))
	if err == nil {
		res.TotalResults = count
	}
	res.Page = filter.Page
	res.Results = media

	return res, nil
}

func (u *Usecase) getTraktRecommendations(
	userId int, profileId int,
	filter models.LibraryFilter,
) ([]models.ZxyMedia, int, error) {
	var res []models.ZxyMedia

	temp, count, err := u.traktUc.GetUsersRecommendations(userId, profileId, filter)
	if err != nil {
		return res, 0, err
	}
	var ids []int
	for _, v := range temp {
		ids = append(ids, int(v.IDS.Tmdb))
	}

	tp := "show"
	if filter.IsMovie {
		tp = "movie"
	}

	res, err = u.localTmdbRepo.GetLibraryFromIdsSameOrder(ids, tp)
	if err != nil {
		return res, 0, err
	}

	return res, count, nil
}

func (u *Usecase) getTraktUserListItems(
	userId int, profileId int,
	filter models.LibraryFilter,
) ([]models.ZxyMedia, int, error) {
	var res []models.ZxyMedia
	temp, count, err := u.traktUc.GetUsersListItems(userId, profileId, filter)
	if err != nil {
		return res, 0, err
	}
	var movieIds []int
	var showIds []int
	for _, v := range temp {
		if v.Movie.IDS.Tmdb != 0 {
			movieIds = append(movieIds, int(v.Movie.IDS.Tmdb))
		} else {
			showIds = append(showIds, int(v.Show.IDS.Tmdb))
		}
	}

	if len(movieIds) != 0 {
		temp, err := u.localTmdbRepo.GetLibraryFromIdsSameOrder(movieIds, "movie")
		if err != nil {
			return res, 0, err
		}
		res = append(res, temp...)
	}
	if len(showIds) != 0 {
		temp, err := u.localTmdbRepo.GetLibraryFromIdsSameOrder(showIds, "show")
		if err != nil {
			return res, 0, err
		}
		res = append(res, temp...)
	}

	return res, count, nil
}

func (u *Usecase) getUserLibraryItems(
	profileId int,
	filter models.LibraryFilter,
) ([]models.ZxyMedia, int, error) {
	var res []models.ZxyMedia
	temp, count, err := u.userRepo.GetUserLibrary(profileId, filter.Page, filter.Items)
	if err != nil {
		return res, 0, apperrors.SomethingWentWrongError{}
	}

	var movieIds []int
	var showIds []int
	for _, v := range temp {
		if v.Type == "movie" {
			movieIds = append(movieIds, v.TmdbId)
		} else {
			showIds = append(showIds, v.TmdbId)
		}
	}

	if len(movieIds) != 0 {
		temp, err := u.localTmdbRepo.GetLibraryFromIdsSameOrder(movieIds, "movie")
		if err != nil {
			return res, 0, err
		}
		res = append(res, temp...)
	}
	if len(showIds) != 0 {
		temp, err := u.localTmdbRepo.GetLibraryFromIdsSameOrder(showIds, "show")
		if err != nil {
			return res, 0, err
		}
		res = append(res, temp...)
	}

	return res, count, nil
}
