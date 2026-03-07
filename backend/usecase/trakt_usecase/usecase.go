package traktusecase

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
	apperrors "zxy/app_errors"
	"zxy/models"
	playbackrepository "zxy/repository/playback_repository"
	userrepository "zxy/repository/user_repository"
	"zxy/utils"

	"github.com/redis/go-redis/v9"
)

const traktApiUrl = "https://api.trakt.tv"
const traktUrl = "https://trakt.tv"

type Usecase struct {
	clientId     string
	clientSecret string
	userRepo     *userrepository.Repository
	playbackRepo *playbackrepository.Repository
	redirectUri  string
	redisClient  *redis.Client
}

func New(
	clientId string,
	clientSecret string,
	userRepo *userrepository.Repository,
	playbackRepo *playbackrepository.Repository,
	redirectUri string,
	redisClient *redis.Client,
) *Usecase {
	usecase := &Usecase{
		clientSecret: clientSecret,
		clientId:     clientId,
		userRepo:     userRepo,
		playbackRepo: playbackRepo,
		redirectUri:  redirectUri,
		redisClient:  redisClient,
	}
	go usecase.runRefreshTraktTokensNearExpiryCron()
	return usecase
}

func (u *Usecase) GetTraktLoginUrl(userId int, profileId int) (string, error) {
	state := utils.GetRandomString(25)
	url := fmt.Sprintf(
		"%s/oauth/authorize?response_type=code&client_id=%s&redirect_uri=%s&state=%s",
		traktUrl,
		u.clientId,
		url.QueryEscape(u.redirectUri),
		state,
	)
	userAndProfile := fmt.Sprintf("%d:%d", userId, profileId)
	_, err := u.redisClient.Set(context.Background(), state, userAndProfile, time.Minute*5).Result()
	if err != nil {
		fmt.Println("Error storing trakt state", err)
		return url, apperrors.SomethingWentWrongError{}
	}

	return url, nil
}

func (u *Usecase) RetrieveUserAuthToken(
	code string,
	state string,
) error {
	userAndProfile, err := u.redisClient.Get(context.Background(), state).Result()
	if err != nil {
		fmt.Println("Error getting state from redis", err)
		return apperrors.SomethingWentWrongError{}
	}
	splitted := strings.Split(userAndProfile, ":")
	userId, _ := strconv.Atoi(splitted[0])
	profileId, _ := strconv.Atoi(splitted[1])

	body := map[string]any{
		"code":          code,
		"client_id":     u.clientId,
		"client_secret": u.clientSecret,
		"redirect_uri":  u.redirectUri,
		"grant_type":    "authorization_code",
	}
	bodyBytes, _ := json.Marshal(body)

	res, err := http.Post(
		fmt.Sprintf("%s/oauth/token", traktApiUrl),
		"application/json",
		bytes.NewReader(bodyBytes),
	)
	resBytes, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println(res.StatusCode)
		fmt.Println("Error reading resposne body ", err)
		return err
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println(res.StatusCode)
		fmt.Println("Error getting auth token ", string(resBytes))
		return fmt.Errorf("Error getting auth token")
	}

	authRes := models.TraktAuthRes{}
	err = json.Unmarshal(resBytes, &authRes)

	if err != nil {
		fmt.Println("Error unmarshalling auth resposne ", err)
		return fmt.Errorf("Error unmarshalling auth resposne %s", err)
	}

	authRes.Expiry = time.Now().Add(time.Second * time.Duration(authRes.ExpiresIn))
	err = u.userRepo.StoreTraktAuthToken(context.Background(), userId, profileId, authRes)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	go u.syncTraktData(userId, profileId, authRes.AccessToken)

	return nil
}

func (u *Usecase) RetrieveUserAuthTokenFromRefreshToken(
	refreshToken string,
) (models.TraktAuthRes, error) {

	body := map[string]any{
		"refresh_token": refreshToken,
		"client_id":     u.clientId,
		"client_secret": u.clientSecret,
		"redirect_uri":  u.redirectUri,
		"grant_type":    "refresh_token",
	}
	bodyBytes, _ := json.Marshal(body)

	res, err := http.Post(
		fmt.Sprintf("%s/oauth/token", traktApiUrl),
		"application/json",
		bytes.NewReader(bodyBytes),
	)
	resBytes, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println(res.StatusCode)
		fmt.Println("Error reading resposne body ", err)
		return models.TraktAuthRes{}, err
	}

	if res.StatusCode != http.StatusOK {
		fmt.Println(res.StatusCode)
		fmt.Println("Error getting auth token ", string(resBytes))
		return models.TraktAuthRes{}, fmt.Errorf("Error getting auth token")
	}

	authRes := models.TraktAuthRes{}
	err = json.Unmarshal(resBytes, &authRes)

	if err != nil {
		fmt.Println("Error unmarshalling auth resposne ", err)
		return authRes, fmt.Errorf("Error unmarshalling auth resposne %s", err)
	}

	authRes.Expiry = time.Now().Add(time.Second * time.Duration(authRes.ExpiresIn))

	return authRes, nil
}

func (u *Usecase) DeleteProfileTraktLogin(userId int, profileId int) error {
	err := u.userRepo.RemoveTraktAuthToken(context.Background(), userId, profileId)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) runRefreshTraktTokensNearExpiryCron() {
	for {
		time.Sleep(time.Hour * 1)
		fmt.Println("Fetching trakt profiles near expiry")
		profilesNearExpiry, err := u.userRepo.GetProfilesWithTraktExpiry(
			time.Now().Add(time.Hour * 6),
		)
		if err != nil {
			fmt.Println("Could not get trakt expiry profiles")
			continue
		}
		fmt.Println("Trakt profiles to update ", len(profilesNearExpiry))
	inner:
		for _, v := range profilesNearExpiry {
			res, err := u.RetrieveUserAuthTokenFromRefreshToken(v.RefreshToken)
			if err != nil {
				fmt.Println("Error getting auth res for ", v.UserId, v.ProfileId)
				fmt.Println("Setting trakt to invalid")
				u.userRepo.SetTraktAuthInvalid(context.Background(), v.UserId, v.ProfileId)
				continue inner
			}
			u.userRepo.StoreTraktAuthToken(context.Background(), v.UserId, v.ProfileId, res)
		}
		fmt.Println("Trak profiles updated")
	}

}
