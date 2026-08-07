package addonusecase

import (
	"context"
	"net/url"
	"slices"
	"strings"
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

func (u *Usecase) AddStreamioAddon(userId int, profileId int, manifestUrl string) error {
	if manifestUrl == "" {
		return apperrors.InvalidInput{Err: "Invalid url"}
	}
	URL, err := url.Parse(manifestUrl)
	if err != nil {
		return apperrors.InvalidInput{Err: "Invalid url"}
	}
	if strings.ToLower(URL.Scheme) != "http" && strings.ToLower(URL.Scheme) != "HTTPS" {
		return apperrors.InvalidInput{Err: "Invalid url"}
	}

	err = u.addonRepo.AddAddon(
		context.Background(),
		models.Addon{Enabled: true, ProfileId: profileId, ManifestUrl: manifestUrl},
	)

	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) UpdateStreamioAddon(profileId int, addonId int, enable bool) error {
	addons, err := u.addonRepo.GetProfileAddons(
		profileId,
	)
	if err != nil {
		return apperrors.InvalidInput{Err: "Addons not found"}
	}
	for _, v := range addons {
		v := v
		if v.Id == addonId {
			v.Enabled = enable
			err := u.addonRepo.UpdateAddon(context.Background(), v)
			if err != nil {
				return apperrors.SomethingWentWrongError{}
			}
			return nil
		}

	}

	return apperrors.InvalidInput{Err: "Addon not found"}
}

func (u *Usecase) RemoveStreamioAddon(profileId int, addonId int) error {
	addons, err := u.addonRepo.GetProfileAddons(
		profileId,
	)
	if err != nil {
		return apperrors.InvalidInput{Err: "Addons not found"}
	}

	for _, v := range addons {
		v := v
		if v.Id == addonId {
			err := u.addonRepo.RemoveProfileAddon(context.Background(), addonId)
			if err != nil {
				return apperrors.SomethingWentWrongError{}
			}
			return nil
		}
	}

	return apperrors.InvalidInput{Err: "Addon not found"}
}
