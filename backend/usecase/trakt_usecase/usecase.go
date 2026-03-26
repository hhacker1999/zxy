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
	traktUser, err := u.getTraktProfile(authRes.AccessToken)
	if err != nil {
		return err
	}

	err = u.userRepo.StoreTraktAuthToken(
		context.Background(),
		userId,
		profileId,
		authRes,
		traktUser,
	)
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

			traktUser, err := u.getTraktProfile(v.Token)
			if err != nil {
				continue inner
			}
			u.userRepo.StoreTraktAuthToken(context.Background(), v.UserId, v.ProfileId, res, traktUser)
		}
		fmt.Println("Trak profiles updated")
	}

}

func (u *Usecase) doTraktPrivateReq(
	req *http.Request,
	traktToken string,
) (*http.Response, error) {
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("trakt-api-version", "2")
	req.Header.Set("trakt-api-key", u.clientId)
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", traktToken))

	return http.DefaultClient.Do(req)
}

func (u *Usecase) getTraktProfile(token string) (models.TraktUser, error) {
	res := models.TraktUser{}
	req, err := http.NewRequest(http.MethodGet, fmt.Sprintf("%s/users/settings", traktApiUrl), nil)
	if err != nil {
		fmt.Println("Error creating get user request", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	profileRes, err := u.doTraktPrivateReq(req, token)
  defer profileRes.Body.Close()
	if err != nil {
		fmt.Println("Error doing trakt profile req", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	resBytes, err := io.ReadAll(profileRes.Body)
	if err != nil {
		fmt.Println(profileRes.StatusCode)
		fmt.Println("Error reading trakt profile response body ", err)
		return res, apperrors.SomethingWentWrongError{}
	}

	if profileRes.StatusCode != http.StatusOK {
		fmt.Println(profileRes.StatusCode)
		fmt.Println("Error getting trakt profile", string(resBytes))
		return res, fmt.Errorf("Error getting trakt profile")
	}

	var traktResponse models.TraktUserSettingsResponse
	err = json.Unmarshal(resBytes, &traktResponse)
	if err != nil {
		fmt.Println("Error unmarshalling profile resposne ", err)
		return res, fmt.Errorf("Error unmarshalling profile resposne %s", err)
	}
	res = traktResponse.User

	return res, nil
}
