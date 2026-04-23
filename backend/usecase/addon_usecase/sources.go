package addonusecase

import (
	"context"
	"slices"
	apperrors "zxy/app_errors"
	"zxy/models"
)

func (u *Usecase) AddSource(userId int, profileId int, tp string, val string) error {
	_, services, presets, err := u.userRepo.GetUserProfile(context.Background(), userId, profileId)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	if tp == models.REAL_DEBRID || tp == models.TORBOX {
		if val == "" {
			return apperrors.InvalidInput{Err: "Invalid key"}
		}
		services[tp] = val
	}
	if tp == models.WEBSTREAMR || tp == models.HDHUB {
		if !slices.Contains(presets, tp) {
			presets = append(presets, tp)
		}
	}

	err = u.userRepo.UpdateServiceAndPreset(
		context.Background(),
		userId,
		profileId,
		services,
		presets,
	)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) RemoveSource(userId int, profileId int, tp string) error {
	_, services, presets, err := u.userRepo.GetUserProfile(context.Background(), userId, profileId)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	if tp == models.REAL_DEBRID || tp == models.TORBOX {
		delete(services, tp)
	}
	if tp == models.WEBSTREAMR || tp == models.HDHUB {
		temp := []string{}
		for _, v := range presets {
			if v != tp {
				temp = append(temp, v)
			}
		}
		presets = temp
	}

	err = u.userRepo.UpdateServiceAndPreset(
		context.Background(),
		userId,
		profileId,
		services,
		presets,
	)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}
