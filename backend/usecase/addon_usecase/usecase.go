package addonusecase

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	apperrors "zxy/app_errors"
	"zxy/models"
	addonsrepository "zxy/repository/addons_repository"
	userrepository "zxy/repository/user_repository"
)

const userPath = "api/v1/user"

type Usecase struct {
	addonUrl  string
	addonRepo *addonsrepository.Repository
	template  string
	instances []string
	tmdbAt    string
	db        *sql.DB
	userRepo  *userrepository.Repository
	zxyUrl    string
}

func New(
	addonUrl string,
	addonRepo *addonsrepository.Repository,
	templatePath string,
	instances string,
	tmdbAt string,
	db *sql.DB,
	userRepo *userrepository.Repository,
	zxyUrl string,
) (*Usecase, error) {

	byte, err := os.ReadFile(templatePath)
	if err != nil {
		fmt.Println("Error reading aio templated", err)
		return nil, err
	}

	instancesSplitted := strings.Split(instances, ",")
	if len(instancesSplitted) == 0 || instancesSplitted[0] == "" {
		fmt.Println("No aio instances provided")
		return nil, fmt.Errorf("No aio instances provided")
	}

	return &Usecase{
		addonUrl:  addonUrl,
		addonRepo: addonRepo,
		template:  string(byte),
		instances: instancesSplitted,
		tmdbAt:    tmdbAt,
		db:        db,
		userRepo:  userRepo,
		zxyUrl:    zxyUrl,
	}, nil
}

func (u *Usecase) StoreAddonFromApiKey(
	userId int,
	profileId int,
	apiKey string,
	debridType string,
) error {
	var config string
	config = u.template
	if debridType == "rd" {
		config = strings.Replace(config, "{rd-enabled}", "true", 1)
		config = strings.Replace(config, "{rd-apiKey}", apiKey, 1)
		config = strings.Replace(config, "{tb-enabled}", "false", 1)
	} else {
		config = strings.Replace(config, "{rd-enabled}", "false", 1)
		config = strings.Replace(config, "{tb-apiKey}", apiKey, 1)
		config = strings.Replace(config, "{tb-enabled}", "true", 1)

	}
	config = strings.Replace(config, "{tmdb-at}", u.tmdbAt, 1)
	config = strings.Replace(config, "{password}", "zxy-app", 1)

	instance := u.instances[0]
	url := fmt.Sprintf("%s/%s", instance, userPath)
	req, err := http.NewRequest(
		http.MethodPost,
		url,
		strings.NewReader(config),
	)
	req.Header.Add("content-type", "application/json")
	if err != nil {
		fmt.Println("Error creating request ", err)
		return apperrors.SomethingWentWrongError{}
	}

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending request ", err)
		return apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()
	bodyBytes, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading body", err)
		return apperrors.SomethingWentWrongError{}
	}
	if res.StatusCode != http.StatusCreated {
		fmt.Println("Invalid status code and body", res.StatusCode, string(bodyBytes))
		return apperrors.SomethingWentWrongError{}
	}

	var temp models.AIOResponse
	err = json.Unmarshal(bodyBytes, &temp)
	if err != nil {
		fmt.Println("Error unmarshallig json response", err)
		return apperrors.SomethingWentWrongError{}
	}

	txn, err := u.db.BeginTx(context.Background(), nil)
	if err != nil {
		fmt.Println("Error creating transaction", err)
		return apperrors.SomethingWentWrongError{}
	}
	defer txn.Rollback()

	ctx := context.WithValue(context.Background(), "txn", txn)

	// Remove old addons
	err = u.addonRepo.RemoveProfileAddons(ctx,
		profileId,
	)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	// Remove new addon
	err = u.addonRepo.AddAddon(ctx, models.Addon{
		ManifestUrl: fmt.Sprintf(
			"%s/stremio/%s/%s/manifest.json",
			instance,
			temp.Data.UUID,
			temp.Data.EncryptedPassword,
		),
		ProfileId: profileId,
		Enabled:   true,
	})
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	// Store debrid info in db
	err = u.userRepo.StoreDebridInfo(ctx, userId, profileId, debridType, apiKey)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = txn.Commit()
	if err != nil {
		fmt.Println("Error committing transaction for adding addon", err)
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) RemoveDebridKey(
	userId int,
	profileId int,
) error {
	txn, err := u.db.BeginTx(context.Background(), nil)
	if err != nil {
		fmt.Println("Error getting transaction object", err)
		return apperrors.SomethingWentWrongError{}
	}
	defer txn.Rollback()

	ctx := context.WithValue(context.Background(), "txn", txn)
	err = u.addonRepo.RemoveProfileAddons(ctx,
		profileId,
	)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = u.userRepo.RemoveDebridKeyFromDB(ctx, userId, profileId)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = txn.Commit()
	if err != nil {
		fmt.Println("Error committing transaction", err)
		return apperrors.SomethingWentWrongError{}
	}

	return nil
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

	// for _, v := range res.Streams {
	// 	if len(v.BehaviorHints.Filename) != 0 {
	// 		info, err := ptn.Parse(v.BehaviorHints.Filename)
	// 		if err != nil {
	// 			fmt.Println("Error parsing file name", err)
	// 		}
	// 		temp := models.StreamResult{
	// 			Name:          v.Name,
	// 			Description:   v.Description,
	// 			Url:           v.URL,
	// 			Resolution:    info.Resolution,
	// 			Container:     info.Container,
	// 			Language:      info.Language,
	// 			BehaviorHints: v.BehaviorHints,
	// 		}
	// 		finalResult = append(finalResult, temp)
	// 	}
	//
	// }

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

	// for _, v := range res.Streams {
	// 	if len(v.BehaviorHints.Filename) != 0 {
	// 		info, err := ptn.Parse(v.BehaviorHints.Filename)
	// 		if err != nil {
	// 			fmt.Println("Error parsing file name", err)
	// 		}
	// 		temp := models.StreamResult{
	// 			Name:          v.Name,
	// 			Description:   v.Description,
	// 			Url:           v.URL,
	// 			Resolution:    info.Resolution,
	// 			Container:     info.Container,
	// 			Language:      info.Language,
	// 			BehaviorHints: v.BehaviorHints,
	// 		}
	// 		finalResult = append(finalResult, temp)
	// 	}
	//
	// }

	return finalResult, nil
}

func (u *Usecase) GetMovieStreamProfile(id string, profileId int) (models.ZxyStreamsRes, error) {
	var res models.ZxyStreamsRes
	var aioRes models.AddonStreamResponse

	addonUrl, err := u.getUserAddonUrl(profileId)
	if err != nil {
		return res, err
	}

	addonResponse, err := http.DefaultClient.Get(
		strings.Replace(
			addonUrl,
			"manifest.json",
			fmt.Sprintf("stream/movie/%s.json", id), 1,
		),
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

	uhd := []models.ZxyResolutionResponse{}
	fhd := []models.ZxyResolutionResponse{}
	hd := []models.ZxyResolutionResponse{}

	for _, v := range aioRes.Streams {
		if v.URL == "" {
			continue
		}
		mp := make(map[string]any)
		err = json.Unmarshal([]byte(v.Name), &mp)
		if err != nil {
			fmt.Println("Error unmarshalling stream name", err)
			return res, apperrors.SomethingWentWrongError{}
		}

		var temp models.ZxyResolutionResponse
		dataMap, ok := mp["stream"].(map[string]any)
		if !ok {
			fmt.Println("stream is not a map")
			continue
		}

		vTags, ok := dataMap["visualTags"].([]any)
		if ok {
			tmp := []string{}
			for _, a := range vTags {
				tg, ok := a.(string)
				if ok {
					tmp = append(tmp, tg)
				}
			}
			temp.VisualTags = tmp
		}
		aTags, ok := dataMap["audioTags"].([]any)
		if ok {
			tmp := []string{}
			for _, a := range aTags {
				tg, ok := a.(string)
				if ok {
					tmp = append(tmp, tg)
				}
			}
			temp.AudioTags = tmp
		}
		lCodes, ok := dataMap["languageCodes"].([]any)
		if ok {
			tmp := []string{}
			for _, a := range lCodes {
				tg, ok := a.(string)
				if ok {
					tmp = append(tmp, tg)
				}
			}
			temp.LanguageCodes = tmp
		}
		fName, ok := dataMap["filename"].(string)
		if ok {
			temp.FileName = fName
		}
		quality, ok := dataMap["quality"].(string)
		if ok {
			temp.Quality = quality
		}
		size, ok := dataMap["size"].(float64)
		if ok {
			temp.Size = size
		}
		temp.Url = fmt.Sprintf("%s/stream?internal=%s", u.zxyUrl, v.URL)
		res, ok := dataMap["resolution"].(string)
		if ok {
			temp.Resolution = res
			if res == "2160p" {
				uhd = append(uhd, temp)
			}
			if res == "1080p" {
				fhd = append(fhd, temp)
			}
			if res == "720p" {
				hd = append(hd, temp)
			}
		} else {
			fmt.Println("resolution not found")
		}
	}

	res.UHD = uhd
	res.FHD = fhd
	res.HD = hd

	return res, nil
}
func (u *Usecase) GetSeriesStreamProfile(
	id string,
	season int,
	episode int,
	profileId int,
) (models.ZxyStreamsRes, error) {
	var res models.ZxyStreamsRes
	var aioRes models.AddonStreamResponse

	addonUrl, err := u.getUserAddonUrl(profileId)
	if err != nil {
		return res, err
	}
	addonResponse, err := http.DefaultClient.Get(
		strings.Replace(
			addonUrl,
			"manifest.json",
			fmt.Sprintf("stream/series/%s:%d:%d.json", id, season, episode), 1,
		),
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

	uhd := []models.ZxyResolutionResponse{}
	fhd := []models.ZxyResolutionResponse{}
	hd := []models.ZxyResolutionResponse{}

	for _, v := range aioRes.Streams {
		if v.URL == "" {
			continue
		}
		mp := make(map[string]any)
		err = json.Unmarshal([]byte(v.Name), &mp)
		if err != nil {
			fmt.Println("Error unmarshalling stream name", err)
		}

		var temp models.ZxyResolutionResponse
		dataMap, ok := mp["stream"].(map[string]any)
		if !ok {
			fmt.Println("stream is not a map")
			continue
		}

		vTags, ok := dataMap["visualTags"].([]any)
		if ok {
			tmp := []string{}
			for _, a := range vTags {
				tg, ok := a.(string)
				if ok {
					tmp = append(tmp, tg)
				}
			}
			temp.VisualTags = tmp
		}
		aTags, ok := dataMap["audioTags"].([]any)
		if ok {
			tmp := []string{}
			for _, a := range aTags {
				tg, ok := a.(string)
				if ok {
					tmp = append(tmp, tg)
				}
			}
			temp.AudioTags = tmp
		}
		lCodes, ok := dataMap["languageCodes"].([]any)
		if ok {
			tmp := []string{}
			for _, a := range lCodes {
				tg, ok := a.(string)
				if ok {
					tmp = append(tmp, tg)
				}
			}
			temp.LanguageCodes = tmp
		}
		fName, ok := dataMap["filename"].(string)
		if ok {
			temp.FileName = fName
		}
		quality, ok := dataMap["quality"].(string)
		if ok {
			temp.Quality = quality
		}
		size, ok := dataMap["size"].(float64)
		if ok {
			temp.Size = size
		}
		temp.Url = fmt.Sprintf("%s/stream?internal=%s", u.zxyUrl, v.URL)
		res, ok := dataMap["resolution"].(string)
		if ok {
			temp.Resolution = res
			if res == "2160p" {
				uhd = append(uhd, temp)
			}
			if res == "1080p" {
				fhd = append(fhd, temp)
			}
			if res == "720p" {
				hd = append(hd, temp)
			}
		} else {
			fmt.Println("resolution not found")
		}
	}

	res.UHD = uhd
	res.FHD = fhd
	res.HD = hd

	return res, nil
}

func (u *Usecase) getUserAddonUrl(profileId int) (string, error) {
	var res string
	addons, err := u.addonRepo.GetProfileAddons(profileId)
	if err != nil {
		if err == sql.ErrNoRows {
			fmt.Println("No addons found")
			return res, apperrors.NoResourcesFound{}
		}
		return res, apperrors.SomethingWentWrongError{}
	}
	if len(addons) == 0 {
		fmt.Println("No addons found")
		return res, apperrors.NoResourcesFound{}
	}

	res = addons[0].ManifestUrl
	return res, nil
}

func (u *Usecase) StoreAddonFromApiKeyContext(
	ctx context.Context,
	userId int,
	profileId int,
	apiKey string,
	debridType string,
) error {
	var config string
	config = u.template
	if debridType == "rd" {
		config = strings.Replace(config, "{rd-enabled}", "true", 1)
		config = strings.Replace(config, "{rd-apiKey}", apiKey, 1)
		config = strings.Replace(config, "{tb-enabled}", "false", 1)
	} else {
		config = strings.Replace(config, "{rd-enabled}", "false", 1)
		config = strings.Replace(config, "{tb-apiKey}", apiKey, 1)
		config = strings.Replace(config, "{tb-enabled}", "true", 1)

	}
	config = strings.Replace(config, "{tmdb-at}", u.tmdbAt, 1)
	config = strings.Replace(config, "{password}", "zxy-app", 1)

	instance := u.instances[0]
	url := fmt.Sprintf("%s/%s", instance, userPath)
	req, err := http.NewRequest(
		http.MethodPost,
		url,
		strings.NewReader(config),
	)
	req.Header.Add("content-type", "application/json")
	if err != nil {
		fmt.Println("Error creating request ", err)
		return apperrors.SomethingWentWrongError{}
	}

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println("Error sending request ", err)
		return apperrors.SomethingWentWrongError{}
	}
	defer res.Body.Close()
	bodyBytes, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println("Error reading body", err)
		return apperrors.SomethingWentWrongError{}
	}
	if res.StatusCode != http.StatusCreated {
		fmt.Println("Invalid status code and body", res.StatusCode, string(bodyBytes))
		return apperrors.SomethingWentWrongError{}
	}

	var temp models.AIOResponse
	err = json.Unmarshal(bodyBytes, &temp)
	if err != nil {
		fmt.Println("Error unmarshallig json response", err)
		return apperrors.SomethingWentWrongError{}
	}

	// Remove old addons
	err = u.addonRepo.RemoveProfileAddons(ctx,
		profileId,
	)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	// Remove new addon
	err = u.addonRepo.AddAddon(ctx, models.Addon{
		ManifestUrl: fmt.Sprintf(
			"%s/stremio/%s/%s/manifest.json",
			instance,
			temp.Data.UUID,
			temp.Data.EncryptedPassword,
		),
		ProfileId: profileId,
		Enabled:   true,
	})
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	// Store debrid info in db
	err = u.userRepo.StoreDebridInfo(ctx, userId, profileId, debridType, apiKey)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}
