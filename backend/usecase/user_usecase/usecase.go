package userusecase

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"math/rand"
	"time"
	apperrors "zxy/app_errors"
	"zxy/models"
	sessionrepository "zxy/repository/session_repository"
	userrepository "zxy/repository/user_repository"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type Usecase struct {
	db          *sql.DB
	userRepo    *userrepository.Repository
	sessionRepo *sessionrepository.Repository
}

func New(
	db *sql.DB,
	userRepo *userrepository.Repository,
	sessionRepo *sessionrepository.Repository,
) *Usecase {
	return &Usecase{
		db:          db,
		userRepo:    userRepo,
		sessionRepo: sessionRepo,
	}
}

func (u *Usecase) Signup(name string, email string, password string) error {
	_, err := u.userRepo.GetUserFromEmail(email)
	if err == nil {
		return apperrors.UserAlreadyRegisteredError{}
	}

	if !errors.Is(err, sql.ErrNoRows) {
		return apperrors.SomethingWentWrongError{}
	}

	if name == "" || email == "" || password == "" {
		return apperrors.InvalidInput{Err: "Invalid user fields"}
	}

	tx, err := u.db.BeginTx(context.Background(), nil)
	if err != nil {
		fmt.Println("Error starting transaction", err)
		return apperrors.SomethingWentWrongError{}
	}
	defer tx.Rollback()

	userId := uuid.New().String()

	pwdHash, err := bcrypt.GenerateFromPassword([]byte(password), 10)
	if err != nil {
		fmt.Println("Error generation password hash", err)
		return apperrors.SomethingWentWrongError{}
	}

	ctx := context.WithValue(context.Background(), "txn", tx)
	id, err := u.userRepo.CreateUser(ctx, models.User{
		Email:   email,
		Name:    name,
		UserId:  userId,
		PwdHash: string(pwdHash),
	})
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = u.userRepo.CreateUserProfile(ctx, models.UserProfile{
		UserId: id,
		Name:   name,
	})
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = tx.Commit()
	if err != nil {
		fmt.Println("Error commiting create user transaction", err)
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) LogInUser(email string, pwd string) (models.User, string, error) {
	user, err := u.userRepo.GetUserFromEmail(email)
	if err != nil {
		if err == sql.ErrNoRows {
			return user, "", apperrors.InvalidInput{Err: "User is not registered"}
		}
		return user, "", apperrors.SomethingWentWrongError{}
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.PwdHash), []byte(pwd))
	if err != nil {
		return user, "", apperrors.InvalidInput{Err: "Invalid password"}
	}

	token := GetRandomString(50)
	err = u.sessionRepo.CreateUserSession(models.Session{
		UserId: user.Id,
		Expiry: time.Now(),
		Token:  token,
	})
	if err != nil {
		return user, token, apperrors.SomethingWentWrongError{}
	}

	return user, token, nil
}

func (u *Usecase) LogInProfile(
	profileId int,
	userId int,
	sessionId int,
	pin string,
) (string, error) {
	user, err := u.userRepo.GetUserFromId(userId)
	if err != nil {
		if err == sql.ErrNoRows {
			return "", apperrors.InvalidInput{Err: "User is not registered"}
		}
		return "", apperrors.SomethingWentWrongError{}
	}

	var found bool
	for _, v := range user.Profiles {
		if v.Id == profileId {
			found = true
			break
		}
	}
	if !found {
		return "", apperrors.InvalidInput{Err: "Invalid Profile"}
	}

	token := GetRandomString(50)
	err = u.sessionRepo.CreateProfileSession(models.ProfileSession{
		ProfileId:    profileId,
		SessionId:    sessionId,
		Token:        token,
		RefreshToken: token,
		Expiry:       time.Now(),
	})
	if err != nil {
		return token, apperrors.SomethingWentWrongError{}
	}

	return token, nil
}

func (u *Usecase) GetUser(userId int) (models.User, error) {
	user, err := u.userRepo.GetUserFromId(userId)
	if err != nil {
		if err == sql.ErrNoRows {
			return user, apperrors.InvalidInput{Err: "User is not registered"}
		}
		return user, apperrors.SomethingWentWrongError{}
	}
	return user, nil
}

func GetRandomString(length int) string {
	const input = "abdcefghijklmnopqrstuvwxyz1234567890"
	var res string

	for range length {
		index := rand.Intn(len(input))

		res += string(input[index])
	}

	return res
}
