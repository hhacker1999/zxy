package userusecase

import apperrors "zxy/app_errors"

func (u *Usecase) AddToLibrary(profileId int, tmdbId int, tp string) error {
	err := u.userRepo.AddToLibrary(profileId, tmdbId, tp)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}
	return nil
}

func (u *Usecase) RemoveFromLibrary(profileId int, tmdbId int, tp string) error {
	err := u.userRepo.RemoveFromLibrary(profileId, tmdbId, tp)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}
	return nil
}
