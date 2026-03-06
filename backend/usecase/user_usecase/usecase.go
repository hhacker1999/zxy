package userusecase

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
	apperrors "zxy/app_errors"
	"zxy/models"
	addonsrepository "zxy/repository/addons_repository"
	playbackrepository "zxy/repository/playback_repository"
	sessionrepository "zxy/repository/session_repository"
	userrepository "zxy/repository/user_repository"
	addonusecase "zxy/usecase/addon_usecase"
	"zxy/utils"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

const hashCost = 10

type Usecase struct {
	db          *sql.DB
	userRepo    *userrepository.Repository
	sessionRepo *sessionrepository.Repository
	pbRepo      *playbackrepository.Repository
	addonRepo   *addonsrepository.Repository
	addonUc     *addonusecase.Usecase
}

func New(
	db *sql.DB,
	userRepo *userrepository.Repository,
	sessionRepo *sessionrepository.Repository,
	pbRepo *playbackrepository.Repository,
	addonRepo *addonsrepository.Repository,
	addonUc *addonusecase.Usecase,
) *Usecase {
	return &Usecase{
		db:          db,
		userRepo:    userRepo,
		sessionRepo: sessionRepo,
		pbRepo:      pbRepo,
		addonRepo:   addonRepo,
		addonUc:     addonUc,
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
		UserId:       id,
		Name:         name,
		IsAdmin:      true,
		LibraryItems: models.DefaultLibraryItems,
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

	token := utils.GetRandomString(50)
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

	token := utils.GetRandomString(50)
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
	if len(profileInput.Name) < 1 || len(profileInput.Name) > 30 {
		return apperrors.InvalidInput{Err: "Name should be between 1 and 15 characters"}
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
		UserId:       profileInput.UserId,
		Name:         profileInput.Name,
		PinHash:      string(pinHash),
		IsAdmin:      profileInput.IsAdmin,
		LibraryItems: models.DefaultLibraryItems,
	})

	if profileInput.UseDefaultProfileKey {
		var profile *models.UserProfile
		for _, v := range user.Profiles {
			if v.Id == profileInput.CreaterProfileId {
				profile = &v
			}
		}
		if profile != nil {
			fullProfile, err := u.userRepo.GetUserProfile(context.Background(), user.Id, profile.Id)
			fmt.Println(profile.Name)
			fmt.Println(profile.DebridKey)
			err = u.addonUc.StoreAddonFromApiKeyContext(
				ctx,
				user.Id,
				profileId,
				fullProfile.DebridKey,
				fullProfile.DebridType,
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

func (u *Usecase) UpdateUserProfile(profileInput CreateProfileInput) error {
	if len(profileInput.Name) < 1 || len(profileInput.Name) > 30 {
		return apperrors.InvalidInput{Err: "Invalid Name"}
	}

	if len(profileInput.Pin) > 0 && len(profileInput.Pin) != 6 {
		return apperrors.InvalidInput{Err: "Pin can only be 6 digits long"}
	}

	profile, err := u.userRepo.GetUserProfile(
		context.Background(),
		profileInput.UserId,
		profileInput.CreaterProfileId,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return apperrors.InvalidInput{Err: "User is not registered"}
		}
		return apperrors.SomethingWentWrongError{}
	}
	// NOTE: This means user is trying other than his own profile
	if profileInput.CreaterProfileId != profileInput.ProfileId {
		if !profile.IsAdmin {
			return apperrors.InvalidInput{Err: "Not authorised to update profile"}
		}
	}

	pinHash := profile.PinHash
	if len(profileInput.Pin) > 0 {
		hsh, err := bcrypt.GenerateFromPassword([]byte(profileInput.Pin), hashCost)
		if err != nil {
			fmt.Println("Error creating pin hash", err)
			return apperrors.SomethingWentWrongError{}
		}
		pinHash = string(hsh)
	}
	err = u.userRepo.UpdateUserProfile(
		context.Background(),
		profileInput.UserId,
		profileInput.ProfileId,
		profileInput.Name,
		pinHash,
	)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) DeleteAccount(userId int, profileId int) error {
	profile, err := u.userRepo.GetUserProfile(
		context.Background(),
		userId, profileId,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return apperrors.InvalidInput{Err: "User is not registered"}
		}
		return apperrors.SomethingWentWrongError{}
	}
	if !profile.IsAdmin {
		return apperrors.InvalidInput{Err: "Not authorised to delete account"}
	}

	user, err := u.userRepo.GetUserFromId(userId)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	txn, err := u.db.BeginTx(context.Background(), nil)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}
	defer txn.Rollback()

	ctx := context.WithValue(context.Background(), "txn", txn)
	for _, v := range user.Profiles {
		err = u.sessionRepo.RemoveProfileSessions(ctx, v.Id)
		if err != nil {
			return apperrors.SomethingWentWrongError{}
		}

		err = u.addonRepo.RemoveProfileAddons(ctx, v.Id)
		if err != nil {
			return apperrors.SomethingWentWrongError{}
		}

		err = u.pbRepo.DeleteProfileProgress(ctx, userId, v.Id)
		if err != nil {
			return apperrors.SomethingWentWrongError{}
		}

		err = u.userRepo.DeleteUserProfile(ctx, userId, v.Id)
		if err != nil {
			return apperrors.SomethingWentWrongError{}
		}

	}

	err = u.sessionRepo.RemoveUserSessions(ctx, userId)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = u.userRepo.DeleteUser(ctx, userId)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = txn.Commit()
	if err != nil {
		fmt.Println("Error comitting transaction", err)
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) DeleteUserProfile(userId int, profileIdToDelete int, profileId int) error {
	profile, err := u.userRepo.GetUserProfile(
		context.Background(),
		userId, profileId,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return apperrors.InvalidInput{Err: "User is not registered"}
		}
		return apperrors.SomethingWentWrongError{}
	}
	if !profile.IsAdmin {
		return apperrors.InvalidInput{Err: "Not authorised to delete profile"}
	}

	txn, err := u.db.BeginTx(context.Background(), nil)
	if err != nil {
		fmt.Println("Erorr creating transaction", err)
		return apperrors.SomethingWentWrongError{}
	}
	defer txn.Rollback()

	ctx := context.WithValue(context.Background(), "txn", txn)

	err = u.sessionRepo.RemoveProfileSessions(ctx, profileIdToDelete)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = u.addonRepo.RemoveProfileAddons(ctx, profileIdToDelete)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = u.pbRepo.DeleteProfileProgress(ctx, userId, profileIdToDelete)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = u.userRepo.DeleteUserProfile(ctx, userId, profileIdToDelete)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}
	err = txn.Commit()
	if err != nil {
		fmt.Println("Error comitting transaction", err)
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) UpdateProfileList(
	userId int,
	profileId int,
	list []models.ProfileLibraryItem,
) error {
	err := u.userRepo.StoreLibraryItems(context.Background(), userId, profileId, list)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}
