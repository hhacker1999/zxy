package traktusecase

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	apperrors "zxy/app_errors"
	"zxy/models"
	playbackrepository "zxy/repository/playback_repository"
	userrepository "zxy/repository/user_repository"
)

const traktUrl = "https://api.trakt.tv"
const redirectUrl = "http://localhost:6969/trakt_redirect/"

type Usecase struct {
	clientId     string
	clientSecret string
	userRepo     *userrepository.Repository
	playbackRepo *playbackrepository.Repository
}

func New(
	clientId string,
	clientSecret string,
	userRepo *userrepository.Repository,
	playbackRepo *playbackrepository.Repository,
) *Usecase {
	return &Usecase{
		clientSecret: clientSecret,
		clientId:     clientId,
		userRepo:     userRepo,
		playbackRepo: playbackRepo,
	}
}

func (u *Usecase) RetrieveUserAuthToken(
	code string,
) error {
	body := map[string]any{
		"code":          code,
		"client_id":     u.clientId,
		"client_secret": u.clientSecret,
		"redirect_uri":  redirectUrl,
		"grant_type":    "authorization_code",
	}
	bodyBytes, _ := json.Marshal(body)

	res, err := http.Post(
		fmt.Sprintf("%s/oauth/token", traktUrl),
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
		fmt.Println("Errro getting auth token ", string(resBytes))
		return fmt.Errorf("Error getting auth token")
	}

	authRes := models.TraktAuthRes{}
	err = json.Unmarshal(resBytes, &authRes)

	if err != nil {
		fmt.Println("Error unmarshalling auth resposne ", err)
		return fmt.Errorf("Error unmarshalling auth resposne %s", err)
	}

	lastTraktLogin, err := u.userRepo.StoreTraktAuthToken(authRes)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	if lastTraktLogin == nil {
		return u.syncTraktData(authRes.AccessToken)
	}

	return nil
}
