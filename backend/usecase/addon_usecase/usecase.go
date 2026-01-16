package addonusecase

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	apperrors "zxy/app_errors"
	"zxy/models"

	"github.com/razsteinmetz/go-ptn"
)

type Usecase struct {
	addonUrl string
}

func New(addonUrl string) *Usecase {
	return &Usecase{
		addonUrl: addonUrl,
	}
}

func (u *Usecase) GetMovieStream(id string) ([]models.StreamResult, error) {
	fmt.Println("Getting movie streams for id ", id)
	var res models.AddonStreamResponse
	addonResponse, err := http.DefaultClient.Get(
		u.addonUrl + fmt.Sprintf("/stream/movie/%s.json", id),
	)
	if err != nil {
		fmt.Println("Error sending movie stream request ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	bodyBytes, err := io.ReadAll(addonResponse.Body)
	if err != nil {
		fmt.Println("Error reading movie stream response ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if addonResponse.StatusCode != http.StatusOK {
		fmt.Println(
			"Invalid status code movie stream request ",
			addonResponse.StatusCode,
			string(bodyBytes),
		)
		return nil, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(bodyBytes, &res)
	if err != nil {
		fmt.Println("Error unmarshalling movie stream response ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	var finalResult []models.StreamResult

	for _, v := range res.Streams {
		if len(v.BehaviorHints.Filename) != 0 {
			info, err := ptn.Parse(v.BehaviorHints.Filename)
			if err != nil {
				fmt.Println("Error parsing file name", err)
			}
			temp := models.StreamResult{
				Name:          v.Name,
				Description:   v.Description,
				Url:           v.URL,
				Resolution:    info.Resolution,
				Container:     info.Container,
				Language:      info.Language,
				BehaviorHints: v.BehaviorHints,
			}
			finalResult = append(finalResult, temp)
		}

	}

	return finalResult, nil
}

func (u *Usecase) GetSeriesStream(
	id string,
	season int,
	episode int,
) ([]models.StreamResult, error) {
	fmt.Println("Getting streams for series ", id, season, episode)
	var res models.AddonStreamResponse
	addonResponse, err := http.DefaultClient.Get(
		u.addonUrl + fmt.Sprintf("/stream/series/%s:%d:%d.json", id, season, episode),
	)
	if err != nil {
		fmt.Println("Error sending series stream request ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	bodyBytes, err := io.ReadAll(addonResponse.Body)
	if err != nil {
		fmt.Println("Error reading series stream response ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	if addonResponse.StatusCode != http.StatusOK {
		fmt.Println(
			"Invalid status code series stream request ",
			addonResponse.StatusCode,
			string(bodyBytes),
		)
		return nil, apperrors.SomethingWentWrongError{}
	}

	err = json.Unmarshal(bodyBytes, &res)
	if err != nil {
		fmt.Println("Error unmarshalling series stream response ", err)
		return nil, apperrors.SomethingWentWrongError{}
	}

	var finalResult []models.StreamResult

	for _, v := range res.Streams {
		if len(v.BehaviorHints.Filename) != 0 {
			info, err := ptn.Parse(v.BehaviorHints.Filename)
			if err != nil {
				fmt.Println("Error parsing file name", err)
			}
			temp := models.StreamResult{
				Name:          v.Name,
				Description:   v.Description,
				Url:           v.URL,
				Resolution:    info.Resolution,
				Container:     info.Container,
				Language:      info.Language,
				BehaviorHints: v.BehaviorHints,
			}
			finalResult = append(finalResult, temp)
		}

	}

	return finalResult, nil
}
