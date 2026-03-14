package addonusecase

import (
	"context"
	"fmt"
	apperrors "zxy/app_errors"
)

func (u *Usecase) AddSource(userId int, profileId int, tp string, val string) error {
	if tp != "rd" && tp != "tb" && tp != "ws" {
		return apperrors.InvalidInput{Err: "Invalid source"}
	}
	if (tp == "rd" || tp == "tb") && len(val) == 0 {
		return apperrors.InvalidInput{Err: "Invalid key"}
	}

	value := fmt.Sprintf(`'%s'`, val)
	if tp == "ws" {
		value = "true"
	}
	err := u.userRepo.UpdateSource(context.Background(), userId, profileId, tp, value)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) RemoveSource(userId int, profileId int, tp string) error {
	if tp != "rd" && tp != "tb" && tp != "ws" {
		return apperrors.InvalidInput{Err: "Invalid source"}
	}

	value := "null"
	if tp == "ws" {
		value = "false"
	}
	err := u.userRepo.UpdateSource(context.Background(), userId, profileId, tp, value)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}
