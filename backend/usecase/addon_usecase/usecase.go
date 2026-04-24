package addonusecase

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
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
	addonUrl       string
	addonRepo      *addonsrepository.Repository
	template       string
	instances      []string
	tmdbAt         string
	db             *sql.DB
	userRepo       *userrepository.Repository
	zxyUrl         string
	encrKey        string
	zxyAioInstance string
	zxyAioUid      string
	zxyAioPwd      string
}

func New(
	addonRepo *addonsrepository.Repository,
	templatePath string,
	instances string,
	tmdbAt string,
	db *sql.DB,
	userRepo *userrepository.Repository,
	zxyUrl string,
	encrKey string,
	zxyAioInstance string,
	zxyAioUid string,
	zxyAioPwd string,
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
		addonRepo:      addonRepo,
		template:       string(byte),
		instances:      instancesSplitted,
		tmdbAt:         tmdbAt,
		db:             db,
		userRepo:       userRepo,
		zxyUrl:         zxyUrl,
		encrKey:        encrKey,
		zxyAioInstance: zxyAioInstance,
		zxyAioUid:      zxyAioUid,
		zxyAioPwd:      zxyAioPwd,
	}, nil
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

func (u *Usecase) GetMovieStreamProfile(
	id string,
	profileId int,
	userIp string,
) (models.ZxyStreamsRes, error) {
	var res models.ZxyStreamsRes
	var aioRes models.AddonStreamResponse

	addonUrl, err := u.getUserAddonUrl(profileId)
	if err != nil {
		return res, err
	}

	req, err := http.NewRequest(http.MethodGet, strings.Replace(
		addonUrl,
		"manifest.json",
		fmt.Sprintf("stream/movie/%s.json", id), 1,
	), nil)
	if err != nil {
		fmt.Println("Error creating movie stream request ", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	req.Header.Set("X-Forwarded-For", userIp)
	req.Header.Set("X-Real-IP", userIp)
	req.Header.Set("X-Client-Ip", userIp)

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

	return u.getStreamUrlCommon(aioRes)
}

func (u *Usecase) GetSeriesStreamProfile(
	id string,
	season int,
	episode int,
	profileId int,
	userIp string,
) (models.ZxyStreamsRes, error) {
	var res models.ZxyStreamsRes
	var aioRes models.AddonStreamResponse

	addonUrl, err := u.getUserAddonUrl(profileId)
	if err != nil {
		return res, err
	}

	req, err := http.NewRequest(http.MethodGet, strings.Replace(
		addonUrl,
		"manifest.json",
		fmt.Sprintf("stream/series/%s:%d:%d.json", id, season, episode), 1,
	), nil)
	if err != nil {
		fmt.Println("Error creating series stream request ", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	req.Header.Set("X-Forwarded-For", userIp)
	req.Header.Set("X-Real-IP", userIp)
	req.Header.Set("X-Client-Ip", userIp)

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

	return u.getStreamUrlCommon(aioRes)
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

func (u *Usecase) encryptURL(url string) (string, error) {
	key, err := hex.DecodeString(u.encrKey)
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonce := make([]byte, gcm.NonceSize())
	io.ReadFull(rand.Reader, nonce)

	ciphertext := gcm.Seal(nonce, nonce, []byte(url), nil)
	return hex.EncodeToString(ciphertext), nil
}

func (u *Usecase) getStreamUrlCommon(
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
			temp.Size = int(size)
		}
		encrypted, err := u.encryptURL(v.URL)
		if err != nil {
			fmt.Println("Error getting encrypted url", err)
			return res, apperrors.SomethingWentWrongError{}
		}
		temp.Url = fmt.Sprintf(
			"%s/stream?internal=%s",
			u.zxyUrl,
			encrypted,
		) // NOTE: This is for proxy
		// temp.Url = fmt.Sprintf("%s/stream?internal=%s", u.zxyUrl, encrypted) // NOTE: This is for normal streaming
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
