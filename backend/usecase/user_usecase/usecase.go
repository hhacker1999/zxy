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

const hashCost = 10

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

	pwdHash, err := bcrypt.GenerateFromPassword([]byte(password), hashCost)
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

	_, err = u.userRepo.CreateUserProfile(ctx, models.UserProfile{
		UserId:  id,
		Name:    name,
		IsAdmin: true,
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

	for i := range len(user.Profiles) {
		v := user.Profiles[i]
		if len(v.PinHash) != 0 {
			fmt.Println("found pin")
			v.IsPinProtected = true
			v.PinHash = ""
			user.Profiles[i] = v
		}
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

	txn, err := u.db.BeginTx(context.Background(), nil)
	if err != nil {
		fmt.Println("Error creating txn", err)
		return "", apperrors.SomethingWentWrongError{}
	}
	defer txn.Rollback()
	ctx := context.WithValue(context.Background(), "txn", txn)

	profile, err := u.userRepo.GetUserProfile(ctx, userId, profileId)
	if err != nil {
		return "", apperrors.SomethingWentWrongError{}
	}

	if len(profile.PinHash) != 0 {
		err = bcrypt.CompareHashAndPassword([]byte(profile.PinHash), []byte(pin))
		if err != nil {
			return "", apperrors.InvalidInput{Err: "Invalid pin"}
		}
	}
	err = u.sessionRepo.RemoveProfileSessions(ctx, profileId)
	if err != nil {
		return "", apperrors.SomethingWentWrongError{}
	}

	token := GetRandomString(50)
	err = u.sessionRepo.CreateProfileSession(ctx, models.ProfileSession{
		ProfileId:    profileId,
		SessionId:    sessionId,
		Token:        token,
		RefreshToken: token,
		Expiry:       time.Now(),
	})
	if err != nil {
		return token, apperrors.SomethingWentWrongError{}
	}

	err = txn.Commit()
	if err != nil {
		fmt.Println("Error comitting transaction", err)
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

	for i := range len(user.Profiles) {
		v := user.Profiles[i]
		if len(v.PinHash) != 0 {
			fmt.Println("found pin")
			v.IsPinProtected = true
			v.PinHash = ""
			user.Profiles[i] = v
		}
	}
	return user, nil
}

func (u *Usecase) GetUserProfile(userId int, profileId int) (models.UserProfile, error) {
	profile, err := u.userRepo.GetUserProfile(context.Background(), userId, profileId)
	if err != nil {
		if err == sql.ErrNoRows {
			return profile, apperrors.InvalidInput{Err: "User is not registered"}
		}
		return profile, apperrors.SomethingWentWrongError{}
	}
	if len(profile.PinHash) != 0 {
		profile.IsPinProtected = true
		profile.PinHash = ""
	}
	return profile, nil
}

func (u *Usecase) CreateUserProfile(profileInput CreateProfileInput) error {
	if len(profileInput.Name) < 1 || len(profileInput.Name) > 10 {
		return apperrors.InvalidInput{Err: "Invalid Name"}
	}

	if len(profileInput.Pin) > 0 && len(profileInput.Pin) != 6 {
		return apperrors.InvalidInput{Err: "Pin can only be 6 digits long"}
	}

	user, err := u.userRepo.GetUserFromId(profileInput.UserId)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}
	if len(user.Profiles) == 4 {
		return apperrors.MaxProfileReachedErorr{}
	}

	txn, err := u.db.BeginTx(context.Background(), nil)
	if err != nil {
		fmt.Println("Error creating transaction", err)
		return apperrors.SomethingWentWrongError{}
	}
	defer txn.Rollback()

	var pinHash []byte
	if len(profileInput.Pin) != 0 {
		pinHash, err = bcrypt.GenerateFromPassword([]byte(profileInput.Pin), hashCost)
		if err != nil {
			fmt.Println("Error generation pin hash", err)
			return apperrors.SomethingWentWrongError{}
		}
	}

	ctx := context.WithValue(context.Background(), "txn", txn)
	profileId, err := u.userRepo.CreateUserProfile(ctx, models.UserProfile{
		UserId:  profileInput.UserId,
		Name:    profileInput.Name,
		PinHash: string(pinHash),
		IsAdmin: profileInput.IsAdmin,
	})

	if profileInput.UseDefaultProfileKey {
		var profile *models.UserProfile
		for _, v := range user.Profiles {
			if v.Id == profileInput.CreaterProfileId {
				profile = &v
			}
		}
		if profile != nil {
			err = u.userRepo.StoreDebridInfo(
				ctx,
				user.Id,
				profileId,
				profile.DebridType,
				profile.DebridKey,
			)
			if err != nil {
				return apperrors.SomethingWentWrongError{}
			}
		}
	}
	err = txn.Commit()
	if err != nil {
		fmt.Println("Error committing transaction", err)
		return apperrors.SomethingWentWrongError{}
	}

	return nil
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
