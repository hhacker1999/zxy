package tmdbusecase

import (
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"sync"
	apperrors "zxy/app_errors"
	"zxy/models"
)

type Usecase struct {
	tmdbApiBaseUrl string
}

func New(tmdbApiBaseUrl string) *Usecase {
	return &Usecase{
		tmdbApiBaseUrl: tmdbApiBaseUrl,
	}
}

func (u *Usecase) GetTrendingMovies(timeline string, page int, at string) ([]byte, error) {

	req, _ := http.NewRequest(
		"GET",
		fmt.Sprintf("%s/trending/movie/%s?page=%d", u.tmdbApiBaseUrl, timeline, page),
		nil,
	)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending trending movies request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from trending movies request to TMDB", res.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of trending movies request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}
	fmt.Println(string(body))

	return body, nil
}

func (u *Usecase) GetTrendingShows(timeline string, page int, at string) ([]byte, error) {

	req, _ := http.NewRequest(
		"GET",
		fmt.Sprintf("%s/trending/tv/%s?page=%d", u.tmdbApiBaseUrl, timeline, page),
		nil,
	)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending trending shows request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from trending shows request to TMDB", res.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of trending shows request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return body, nil
}

func (u *Usecase) GetMovieLibrary(params map[string]string, at string) ([]byte, error) {
	url := fmt.Sprintf(
		"%s/discover/movie?include_video=false&language=en-US",
		u.tmdbApiBaseUrl,
	)
	for k, v := range params {
		url += fmt.Sprintf("&%s=%s", k, v)
	}

	fmt.Println("--------------------------------------------------")
	fmt.Println("Final uri is ", url)
	fmt.Println("--------------------------------------------------")

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending discover movies request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from discover movies request to TMDB", res.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of discover movies request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return body, nil
}

func (u *Usecase) GetShowsLibrary(params map[string]string, at string) ([]byte, error) {
	url := fmt.Sprintf(
		"%s/discover/tv?include_video=false&language=en-US",
		u.tmdbApiBaseUrl,
	)
	for k, v := range params {
		url += fmt.Sprintf("&%s=%s", k, v)
	}

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending discover movies request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from discover movies request to TMDB", res.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of discover movies request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return body, nil
}
func (u *Usecase) GetMovieDetails(id string, at string) (models.TMDBMovie, error) {
	var response models.TMDBMovie
	url := fmt.Sprintf(
		"%s/movie/%s?append_to_response=credits,images,external_ids,similar,belongs_to_collection",
		u.tmdbApiBaseUrl, id,
	)

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending get movie request to TMDB", err)
		return response, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from get movie request to TMDB", res.StatusCode)
		return response, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of get movie request to TMDB", err)
		return response, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(body, &response)
	if err != nil {
		fmt.Println("Error unmarshalling get movie response", err)
		return response, apperrors.SomethingWentWrongError{}
	}

	if response.BelongsToCollection.ID != 0 {

		url = fmt.Sprintf(
			"%s/collection/%d",
			u.tmdbApiBaseUrl,
			response.BelongsToCollection.ID,
		)

		req, _ = http.NewRequest("GET", url, nil)

		req.Header.Add("accept", "application/json")
		req.Header.Add(
			"Authorization",
			fmt.Sprintf("Bearer %s", at),
		)

		res, err = http.DefaultClient.Do(req)
		if err != nil {
			fmt.Println("Error sending get collection request to TMDB", err)
			return response, apperrors.SomethingWentWrongError{}
		}

		if res.StatusCode != http.StatusOK {
			fmt.Println("Invalid status code from get collection request to TMDB", res.StatusCode)
			return response, apperrors.SomethingWentWrongError{}
		}

		defer res.Body.Close()
		body, err := io.ReadAll(res.Body)
		if err != nil {
			fmt.Println("Error reading response of get collection request to TMDB", err)
			return response, apperrors.SomethingWentWrongError{}
		}

		var collection models.Collection
		err = json.Unmarshal(body, &collection)
		if err != nil {
			fmt.Println("Error unmarshalling get collection response", err)
			return response, apperrors.SomethingWentWrongError{}
		}
		response.Collection = collection
	}

	return response, nil
}

func (u *Usecase) GetShowDetails(id string, at string) (models.TMDBShow, error) {
	var details models.TMDBShow
	url := fmt.Sprintf(
		"%s/tv/%s?append_to_response=credits,external_ids,images,similar",
		u.tmdbApiBaseUrl, id,
	)

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending get series request to TMDB", err)
		return details, apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of get series request to TMDB", err)
		return details, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println(
			"Invalid status code from get series request to TMDB",
			res.StatusCode,
			string(body),
		)
		return details, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(body, &details)
	if err != nil {
		fmt.Println("Error unmarshalling show response", err)
		return details, apperrors.SomethingWentWrongError{}
	}

	var seasons []models.Season

	seasonInOneIteration := 10
	iterations := int(math.Ceil((float64(len(details.Seasons)) / float64(seasonInOneIteration))))
	for iteration := range iterations {
		keys := []string{}
		url = fmt.Sprintf(
			"%s/tv/%s?append_to_response=",
			u.tmdbApiBaseUrl, id,
		)
	inner:
		for i := range seasonInOneIteration {
			index := i + (seasonInOneIteration * iteration)
			maxIndex := (seasonInOneIteration - 1) + (seasonInOneIteration * iteration)
			if index >= len(details.Seasons) {
				break inner
			}
			currSeason := details.Seasons[index]
			if currSeason.SeasonNumber == 0 {
				continue inner
			}
			seasonKey := fmt.Sprintf("season/%d", currSeason.SeasonNumber)
			url += seasonKey
			keys = append(keys, seasonKey)
			if index != maxIndex && maxIndex != len(details.Seasons)-1 {
				url += ","
			}
		}
		req, _ = http.NewRequest("GET", url, nil)

		req.Header.Add("accept", "application/json")
		req.Header.Add(
			"Authorization",
			fmt.Sprintf("Bearer %s", at),
		)

		res, err = http.DefaultClient.Do(req)
		if err != nil {
			fmt.Println("Error sending get series request to TMDB", err)
			return details, apperrors.SomethingWentWrongError{}
		}

		defer res.Body.Close()
		body, err = io.ReadAll(res.Body)
		if err != nil {
			fmt.Println("Error reading response of get series request to TMDB", err)
			return details, apperrors.SomethingWentWrongError{}
		}

		if res.StatusCode != http.StatusOK {
			fmt.Println(
				"Invalid status code from get series request to TMDB",
				res.StatusCode,
				string(body),
			)
			return details, apperrors.SomethingWentWrongError{}
		}

		rawMap := make(map[string]json.RawMessage, 0)
		err = json.Unmarshal(body, &rawMap)
		if err != nil {
			fmt.Println("Error unmarshalling show response", err)
			return details, apperrors.SomethingWentWrongError{}
		}
		for _, k := range keys {
			var temp models.Season
			err = json.Unmarshal(rawMap[k], &temp)
			if err != nil {
				fmt.Println("Error unmarshalling show season response", err)
				return details, apperrors.SomethingWentWrongError{}
			}
			seasons = append(seasons, temp)
		}
	}

	details.Seasons = seasons

	return details, nil
}

func (u *Usecase) GetSeasonDetails(id string, season string, at string) ([]byte, error) {
	url := fmt.Sprintf(
		"%s/tv/%s/season/%s",
		u.tmdbApiBaseUrl, id, season,
	)

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending get season request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from get season request to TMDB", res.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of get season request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return body, nil
}

func (u *Usecase) GetEpisodeDetails(
	id string,
	season string,
	episode string,
	at string,
) ([]byte, error) {
	url := fmt.Sprintf(
		"%s/tv/%s/season/%s/episode/%s",
		u.tmdbApiBaseUrl, id, season, episode,
	)

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending get episode request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from get episode request to TMDB", res.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of get episode request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return body, nil
}

func (u *Usecase) GetGenres(at string) (models.ZxyGenreResponse, error) {
	wg := sync.WaitGroup{}

	var movieGenre []models.Genre
	var showGenre []models.Genre
	var err error
	wg.Add(2)
	go func() {
		defer wg.Done()
		movieGenre, err = u.getTMDBMovieGenre(at)
	}()

	go func() {
		defer wg.Done()
		showGenre, err = u.getTMDBShowGenre(at)
	}()
	wg.Wait()
	if err != nil {
		return models.ZxyGenreResponse{}, err
	}

	return models.ZxyGenreResponse{MovieGenre: movieGenre, ShowGenre: showGenre}, nil
}

func (u *Usecase) getTMDBMovieGenre(at string) ([]models.Genre, error) {

	url := fmt.Sprintf("%s/genre/movie/list?language=en", u.tmdbApiBaseUrl)

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending get movie genre ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading get movie genre ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println(
			"Invalid status code when calling get movie genre ",
			res.StatusCode,
			string(body),
		)
		return nil, apperrors.SomethingWentWrongError{}
	}

	var tmdbRes models.TMDBGenreResponse
	err = json.Unmarshal(body, &tmdbRes)

	if err != nil {
		fmt.Println("Error unmarshalling get movie genre ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return tmdbRes.Genres, nil
}

func (u *Usecase) getTMDBShowGenre(at string) ([]models.Genre, error) {
	url := fmt.Sprintf("%s/genre/tv/list?language=en", u.tmdbApiBaseUrl)

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending get show genre ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading get show genre ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println(
			"Invalid status code when calling get show genre ",
			res.StatusCode,
			string(body),
		)
		return nil, apperrors.SomethingWentWrongError{}
	}

	var tmdbRes models.TMDBGenreResponse
	err = json.Unmarshal(body, &tmdbRes)

	if err != nil {
		fmt.Println("Error unmarshalling get show genre ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return tmdbRes.Genres, nil
}

func (u *Usecase) SearchMovie(at string, page int, keyword string) ([]byte, error) {
	url := fmt.Sprintf(
		"%s/search/movie?include_adult=false&language=en-US&page=%d&query=%s",
		u.tmdbApiBaseUrl, page, keyword,
	)

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending search movies request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from search movies request to TMDB", res.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of search movies request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return body, nil
}

func (u *Usecase) SearchShows(at string, page int, keyword string) ([]byte, error) {
	url := fmt.Sprintf(
		"%s/search/tv?include_adult=false&language=en-US&page=%d&query=%s",
		u.tmdbApiBaseUrl, page, keyword,
	)

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add(
		"Authorization",
		fmt.Sprintf("Bearer %s", at),
	)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending search shows request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from search shows request to TMDB", res.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of search shows request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return body, nil
}

func (u *Usecase) GetConfiguration(at string) ([]byte, error) {
	req, _ := http.NewRequest("GET", u.tmdbApiBaseUrl+"/configuration", nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", at))

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending get configuration ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading get configuration", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println(
			"Invalid status code when calling get configuration ",
			res.StatusCode,
			string(body),
		)
		return nil, apperrors.SomethingWentWrongError{}
	}

	return body, nil
}
