package tmdbusecase

import (
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"strconv"
	"sync"
	"time"
	apperrors "zxy/app_errors"
	"zxy/models"
	localtmdbrepository "zxy/repository/local_tmdb_repository"
)

type Usecase struct {
	tmdbApiBaseUrl string
	client         *http.Client
	localTmdbRepo  *localtmdbrepository.Repository
}

func New(tmdbApiBaseUrl string, localTmdbRepo *localtmdbrepository.Repository) *Usecase {
	var tmdbClient = &http.Client{
		Timeout: 10 * time.Second,
		Transport: &http.Transport{
			MaxIdleConns:        100,
			MaxIdleConnsPerHost: 20,
			MaxConnsPerHost:     10,
			IdleConnTimeout:     20 * time.Second,
			TLSHandshakeTimeout: 10 * time.Second,
		},
	}
	return &Usecase{
		tmdbApiBaseUrl: tmdbApiBaseUrl,
		client:         tmdbClient,
		localTmdbRepo:  localTmdbRepo,
	}
}

func (u *Usecase) GetTrendingMovies(
	timeline string,
	page int,
	at string,
) (models.MediaPaginatedResponse, error) {
	var resp models.MediaPaginatedResponse

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

	res, err := u.client.Do(req)
	if err != nil {
		fmt.Println("Error sending trending movies request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from trending movies request to TMDB", res.StatusCode)
		return resp, apperrors.SomethingWentWrongError{}
	}

	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of trending movies request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}
	err = json.Unmarshal(body, &resp)
	if err != nil {
		fmt.Println("Error unmarshalling trending movies", err)
		return resp, apperrors.SomethingWentWrongError{}
	}

	ids := []int{}
	for _, v := range resp.Results {
		ids = append(ids, int(v.ID))
	}

	ratings, err := u.localTmdbRepo.GetImdbRatingsFromTmdb(ids, "movie")
	if err != nil {
		return resp, apperrors.SomethingWentWrongError{}
	}

	for i := range len(resp.Results) {
		v := resp.Results[i]
		rating, ok := ratings[int(v.ID)]
		if ok {
			v.ImdbRating = rating
			resp.Results[i] = v
		}
	}

	return resp, nil
}

func (u *Usecase) GetTrendingShows(
	timeline string,
	page int,
	at string,
) (models.MediaPaginatedResponse, error) {
	var resp models.MediaPaginatedResponse

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

	res, err := u.client.Do(req)
	if err != nil {
		fmt.Println("Error sending trending shows request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from trending shows request to TMDB", res.StatusCode)
		return resp, apperrors.SomethingWentWrongError{}
	}

	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of trending shows request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}
	err = json.Unmarshal(body, &resp)
	if err != nil {
		fmt.Println("Error unmarshalling trending movies", err)
		return resp, apperrors.SomethingWentWrongError{}
	}

	ids := []int{}
	for _, v := range resp.Results {
		ids = append(ids, int(v.ID))
	}

	ratings, err := u.localTmdbRepo.GetImdbRatingsFromTmdb(ids, "show")
	if err != nil {
		return resp, apperrors.SomethingWentWrongError{}
	}

	for i := range len(resp.Results) {
		v := resp.Results[i]
		rating, ok := ratings[int(v.ID)]
		if ok {
			v.ImdbRating = rating
			resp.Results[i] = v
		}
	}

	return resp, nil
}

func (u *Usecase) GetMovieLibrary(
	params map[string]string,
	at string,
) (models.MediaPaginatedResponse, error) {
	var resp models.MediaPaginatedResponse
	url := fmt.Sprintf(
		"%s/discover/movie?include_video=false&language=en-US",
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

	res, err := u.client.Do(req)
	if err != nil {
		fmt.Println("Error sending discover movies request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from discover movies request to TMDB", res.StatusCode)
		return resp, apperrors.SomethingWentWrongError{}
	}

	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of discover movies request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}
	err = json.Unmarshal(body, &resp)
	if err != nil {
		fmt.Println("Error unmarshalling trending movies", err)
		return resp, apperrors.SomethingWentWrongError{}
	}

	ids := []int{}
	for _, v := range resp.Results {
		ids = append(ids, int(v.ID))
	}

	ratings, err := u.localTmdbRepo.GetImdbRatingsFromTmdb(ids, "movie")
	if err != nil {
		return resp, apperrors.SomethingWentWrongError{}
	}

	for i := range len(resp.Results) {
		v := resp.Results[i]
		rating, ok := ratings[int(v.ID)]
		if ok {
			v.ImdbRating = rating
			resp.Results[i] = v
		}
	}

	return resp, nil
}

func (u *Usecase) GetShowsLibrary(
	params map[string]string,
	at string,
) (models.MediaPaginatedResponse, error) {
	var resp models.MediaPaginatedResponse
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

	res, err := u.client.Do(req)
	if err != nil {
		fmt.Println("Error sending discover movies request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from discover movies request to TMDB", res.StatusCode)
		return resp, apperrors.SomethingWentWrongError{}
	}

	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of discover movies request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(body, &resp)
	if err != nil {
		fmt.Println("Error unmarshalling trending movies", err)
		return resp, apperrors.SomethingWentWrongError{}
	}

	ids := []int{}
	for _, v := range resp.Results {
		ids = append(ids, int(v.ID))
	}

	ratings, err := u.localTmdbRepo.GetImdbRatingsFromTmdb(ids, "show")
	if err != nil {
		return resp, apperrors.SomethingWentWrongError{}
	}

	for i := range len(resp.Results) {
		v := resp.Results[i]
		rating, ok := ratings[int(v.ID)]
		if ok {
			v.ImdbRating = rating
			resp.Results[i] = v
		}
	}

	return resp, nil
}
func (u *Usecase) GetMovieDetails(id string, at string) (models.TMDBMovie, error) {
	var response models.TMDBMovie
	var err error

	// NOTE: check local db first
	idInt, err := strconv.Atoi(id)
	if err != nil {
		return response, apperrors.InvalidInput{Err: "Invalid id"}
	}

	response, err = u.localTmdbRepo.GetMovie(idInt)
	if err != nil {
		fmt.Println("Movie not found in local db")
		url := fmt.Sprintf(
			"%s/movie/%s?append_to_response=credits,images,external_ids,similar,belongs_to_collection,videos,watch/providers,recommendations",
			u.tmdbApiBaseUrl,
			id,
		)

		req, _ := http.NewRequest("GET", url, nil)
		req.Header.Add("accept", "application/json")
		req.Header.Add(
			"Authorization",
			fmt.Sprintf("Bearer %s", at),
		)

		res, err := u.client.Do(req)
		if err != nil {
			fmt.Println("Error sending get movie request to TMDB", err)
			return response, apperrors.SomethingWentWrongError{}
		}
		defer res.Body.Close()

		if res.StatusCode != http.StatusOK {
			fmt.Println("Invalid status code from get movie request to TMDB", res.StatusCode)
			return response, apperrors.SomethingWentWrongError{}
		}

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

			res, err = u.client.Do(req)
			if err != nil {
				fmt.Println("Error sending get collection request to TMDB", err)
				return response, apperrors.SomethingWentWrongError{}
			}
			defer res.Body.Close()

			if res.StatusCode != http.StatusOK {
				fmt.Println(
					"Invalid status code from get collection request to TMDB",
					res.StatusCode,
				)
				return response, apperrors.SomethingWentWrongError{}
			}

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
		go u.localTmdbRepo.InsertDetails(int(response.ID), "movie", response)
	}

	ids := []int{}
	if response.ImdbRating == 0 {
		ids = append(ids, int(response.ID))
	}
	for _, v := range response.Similar.Results {
		ids = append(ids, int(v.ID))
	}
	for _, v := range response.Recommendations.Results {
		ids = append(ids, int(v.ID))
	}
	for _, v := range response.Collection.Parts {
		ids = append(ids, int(v.ID))
	}

	ratings, err := u.localTmdbRepo.GetImdbRatingsFromTmdb(ids, "movie")
	if err != nil {
		return response, nil
	}

	if response.ImdbRating == 0 {
		rating, ok := ratings[int(response.ID)]
		if ok {
			response.ImdbRating = rating
		}
	}

	for i := range len(response.Similar.Results) {
		v := response.Similar.Results[i]
		rating, ok := ratings[int(v.ID)]
		if ok {
			v.ImdbRating = rating
		}
		response.Similar.Results[i] = v
	}

	for i := range len(response.Recommendations.Results) {
		v := response.Recommendations.Results[i]
		rating, ok := ratings[int(v.ID)]
		if ok {
			v.ImdbRating = rating
		}
		response.Recommendations.Results[i] = v
	}

	for i := range len(response.Collection.Parts) {
		v := response.Collection.Parts[i]
		rating, ok := ratings[int(v.ID)]
		if ok {
			v.ImdbRating = rating
		}
		response.Collection.Parts[i] = v
	}

	return response, nil
}

func (u *Usecase) GetShowDetails(id string, at string) (models.TMDBShow, error) {
	var response models.TMDBShow
	var err error
	idInt, err := strconv.Atoi(id)
	if err != nil {
		return response, apperrors.InvalidInput{Err: "Invalid id"}
	}
	response, err = u.localTmdbRepo.GetShow(idInt)
	if err != nil {
		url := fmt.Sprintf(
			"%s/tv/%s?append_to_response=credits,external_ids,images,similar,videos,watch/providers,recommendations",
			u.tmdbApiBaseUrl,
			id,
		)

		req, _ := http.NewRequest("GET", url, nil)

		req.Header.Add("accept", "application/json")
		req.Header.Add(
			"Authorization",
			fmt.Sprintf("Bearer %s", at),
		)

		res, err := u.client.Do(req)
		if err != nil {
			fmt.Println("Error sending get series request to TMDB", err)
			return response, apperrors.SomethingWentWrongError{}
		}
		defer res.Body.Close()

		body, err := io.ReadAll(res.Body)
		if err != nil {
			fmt.Println("Error reading response of get series request to TMDB", err)
			return response, apperrors.SomethingWentWrongError{}
		}

		if res.StatusCode != http.StatusOK {
			fmt.Println(
				"Invalid status code from get series request to TMDB",
				res.StatusCode,
				string(body),
			)
			return response, apperrors.SomethingWentWrongError{}
		}

		err = json.Unmarshal(body, &response)
		if err != nil {
			fmt.Println("Error unmarshalling show response", err)
			return response, apperrors.SomethingWentWrongError{}
		}

		var seasons []models.Season

		seasonInOneIteration := 10
		iterations := int(
			math.Ceil((float64(len(response.Seasons)) / float64(seasonInOneIteration))),
		)
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
				if index >= len(response.Seasons) {
					break inner
				}
				currSeason := response.Seasons[index]
				if currSeason.SeasonNumber == 0 {
					continue inner
				}
				seasonKey := fmt.Sprintf("season/%d", currSeason.SeasonNumber)
				url += seasonKey
				keys = append(keys, seasonKey)
				if index < len(response.Seasons)-1 && index < maxIndex {
					url += ","
				}
			}
			req, _ = http.NewRequest("GET", url, nil)

			req.Header.Add("accept", "application/json")
			req.Header.Add(
				"Authorization",
				fmt.Sprintf("Bearer %s", at),
			)

			res, err = u.client.Do(req)
			if err != nil {
				fmt.Println("Error sending get series request to TMDB", err)
				return response, apperrors.SomethingWentWrongError{}
			}

			defer res.Body.Close()
			body, err = io.ReadAll(res.Body)
			if err != nil {
				fmt.Println("Error reading response of get series request to TMDB", err)
				return response, apperrors.SomethingWentWrongError{}
			}

			if res.StatusCode != http.StatusOK {
				fmt.Println(
					"Invalid status code from get series request to TMDB",
					res.StatusCode,
					string(body),
				)
				return response, apperrors.SomethingWentWrongError{}
			}

			rawMap := make(map[string]json.RawMessage, 0)
			err = json.Unmarshal(body, &rawMap)
			if err != nil {
				fmt.Println("Error unmarshalling show response", err)
				return response, apperrors.SomethingWentWrongError{}
			}
			for _, k := range keys {
				var temp models.Season
				data, ok := rawMap[k]
				if !ok {
					fmt.Println("could not find data for season ", k)
					continue
				}
				err = json.Unmarshal(data, &temp)
				if err != nil {
					fmt.Println("Error unmarshalling show season response", err)
					return response, apperrors.SomethingWentWrongError{}
				}
				seasons = append(seasons, temp)
			}
		}
		response.Seasons = seasons
		go u.localTmdbRepo.InsertDetails(int(response.ID), "show", response)
	}

	ids := []int{}
	if response.ImdbRating == 0 {
		ids = append(ids, int(response.ID))
	}
	for _, v := range response.Similar.Results {
		ids = append(ids, int(v.ID))
	}
	for _, v := range response.Recommendations.Results {
		ids = append(ids, int(v.ID))
	}

	ratings, err := u.localTmdbRepo.GetImdbRatingsFromTmdb(ids, "show")
	if err != nil {
		return response, nil
	}

	if response.ImdbRating == 0 {
		rating, ok := ratings[int(response.ID)]
		if ok {
			response.ImdbRating = rating
		}
	}

	for i := range len(response.Similar.Results) {
		v := response.Similar.Results[i]
		rating, ok := ratings[int(v.ID)]
		if ok {
			v.ImdbRating = rating
		}
		response.Similar.Results[i] = v
	}

	for i := range len(response.Recommendations.Results) {
		v := response.Recommendations.Results[i]
		rating, ok := ratings[int(v.ID)]
		if ok {
			v.ImdbRating = rating
		}
		response.Recommendations.Results[i] = v
	}

	return response, nil
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

	res, err := u.client.Do(req)
	if err != nil {
		fmt.Println("Error sending get season request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from get season request to TMDB", res.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

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

	res, err := u.client.Do(req)
	if err != nil {
		fmt.Println("Error sending get episode request to TMDB", err)
		return nil, apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from get episode request to TMDB", res.StatusCode)
		return nil, apperrors.SomethingWentWrongError{}
	}

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
	errChan := make(chan error, 2)
	wg.Add(2)
	go func() {
		defer wg.Done()
		movieGenreRes, err := u.getTMDBMovieGenre(at)
		if err != nil {
			errChan <- err
		}
		movieGenre = movieGenreRes
	}()

	go func() {
		defer wg.Done()
		showGenreRes, err := u.getTMDBShowGenre(at)
		if err != nil {
			errChan <- err
		}
		showGenre = showGenreRes
	}()
	wg.Wait()
	close(errChan)
	for v := range errChan {
		return models.ZxyGenreResponse{}, v
	}

	return models.ZxyGenreResponse{MovieGenre: movieGenre, ShowGenre: showGenre}, nil
}

func (u *Usecase) getTMDBMovieGenre(at string) ([]models.Genre, error) {

	url := fmt.Sprintf("%s/genre/movie/list?language=en", u.tmdbApiBaseUrl)

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Set("accept", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", at))
	req.Header.Set(
		"User-Agent",
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36",
	)

	res, err := u.client.Do(req)
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

	req.Header.Set("accept", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", at))
	req.Header.Set(
		"User-Agent",
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36",
	)

	res, err := u.client.Do(req)
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

func (u *Usecase) SearchMovie(
	at string,
	page int,
	keyword string,
) (models.MediaPaginatedResponse, error) {
	var resp models.MediaPaginatedResponse

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

	res, err := u.client.Do(req)
	if err != nil {
		fmt.Println("Error sending search movies request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from search movies request to TMDB", res.StatusCode)
		return resp, apperrors.SomethingWentWrongError{}
	}

	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of search movies request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(body, &resp)
	if err != nil {
		fmt.Println("Error unmarshalling trending movies", err)
		return resp, apperrors.SomethingWentWrongError{}
	}

	ids := []int{}
	for _, v := range resp.Results {
		ids = append(ids, int(v.ID))
	}

	ratings, err := u.localTmdbRepo.GetImdbRatingsFromTmdb(ids, "movie")
	if err != nil {
		return resp, apperrors.SomethingWentWrongError{}
	}

	for i := range len(resp.Results) {
		v := resp.Results[i]
		rating, ok := ratings[int(v.ID)]
		if ok {
			v.ImdbRating = rating
			resp.Results[i] = v
		}
	}
	return resp, nil
}

func (u *Usecase) SearchShows(
	at string,
	page int,
	keyword string,
) (models.MediaPaginatedResponse, error) {
	var resp models.MediaPaginatedResponse

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

	res, err := u.client.Do(req)
	if err != nil {
		fmt.Println("Error sending search shows request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		fmt.Println("Invalid status code from search shows request to TMDB", res.StatusCode)
		return resp, apperrors.SomethingWentWrongError{}
	}

	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading response of search shows request to TMDB", err)
		return resp, apperrors.SomethingWentWrongError{}
	}
	err = json.Unmarshal(body, &resp)
	if err != nil {
		fmt.Println("Error unmarshalling trending movies", err)
		return resp, apperrors.SomethingWentWrongError{}
	}

	ids := []int{}
	for _, v := range resp.Results {
		ids = append(ids, int(v.ID))
	}

	ratings, err := u.localTmdbRepo.GetImdbRatingsFromTmdb(ids, "show")
	if err != nil {
		return resp, apperrors.SomethingWentWrongError{}
	}

	for i := range len(resp.Results) {
		v := resp.Results[i]
		rating, ok := ratings[int(v.ID)]
		if ok {
			v.ImdbRating = rating
			resp.Results[i] = v
		}
	}

	return resp, nil
}

func (u *Usecase) GetConfiguration(at string) ([]byte, error) {
	req, _ := http.NewRequest("GET", u.tmdbApiBaseUrl+"/configuration", nil)

	req.Header.Set("accept", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", at))
	req.Header.Set(
		"User-Agent",
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36",
	)

	res, err := u.client.Do(req)
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
