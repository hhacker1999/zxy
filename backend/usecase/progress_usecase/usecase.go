package progressusecase

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"
	apperrors "zxy/app_errors"
	playbackrepository "zxy/repository/playback_repository"
	tmdbusecase "zxy/usecase/tmdb_usecase"
)

const layout = "2006-01-02"
const continueWatchingThreshold = 90.00

const at = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU"

type Usecase struct {
	db     *sql.DB
	tmdbUC *tmdbusecase.Usecase
	pbr    *playbackrepository.Repository
}

func New(db *sql.DB, tmdbUC *tmdbusecase.Usecase, pbr *playbackrepository.Repository) *Usecase {
	return &Usecase{
		db:     db,
		tmdbUC: tmdbUC,
		pbr:    pbr,
	}
}

func (u *Usecase) GetContinueWatching(
	userId int,
	profileId int,
) ([]playbackrepository.ProgressUpdate, error) {

	res, err := u.pbr.GetProgressMultiple(
		userId,
		profileId,
		"",
		false,
		continueWatchingThreshold,
		0,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		} else {
			return nil, apperrors.SomethingWentWrongError{}
		}
	}

	return res, nil
}

func (u *Usecase) GetShowProgress(
	userId int,
	profileId int,
	showId string,
) ([]playbackrepository.ProgressUpdate, error) {

	res, err := u.pbr.GetProgressMultiple(
		userId,
		profileId,
		showId,
		true,
		0,
		0,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		} else {
			return nil, apperrors.SomethingWentWrongError{}
		}
	}

	return res, nil
}

func (u *Usecase) GetMovieProgress(
	userId int,
	profileId int,
	movieId string,
) (playbackrepository.ProgressUpdate, error) {
	res, err := u.pbr.GetProgress(
		userId,
		profileId,
		movieId,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return playbackrepository.ProgressUpdate{}, nil
		} else {
			return playbackrepository.ProgressUpdate{}, apperrors.SomethingWentWrongError{}
		}
	}

	return res, nil
}

func (u *Usecase) UpdatePlaybackProgress(
	userId int,
	profileId int,
	mediaId string,
	progress float64,
) error {
	if len(mediaId) == 0 {
		return apperrors.InvalidInput{Err: "Invalid Media Id"}
	}

	splitted := strings.Split(mediaId, ":")
	if len(splitted) == 1 {
		err := u.pbr.UpdateProgress(context.Background(), []playbackrepository.ProgressUpdate{
			{
				UserId:    userId,
				MediaId:   mediaId,
				ProfileId: profileId,
				Progress:  progress,
				IsWatched: progress > 85,
			},
		})
		return err
	}

	// TODO: add actual watched check of shows here
	err := u.pbr.UpdateProgress(context.Background(), []playbackrepository.ProgressUpdate{
		{
			UserId:    userId,
			MediaId:   mediaId,
			ProfileId: profileId,
			Progress:  progress,
			IsWatched: progress > 85,
		},
	})
	return err

}

func (u *Usecase) MarkMovieWatched(
	userId int,
	profileId int,
	movieId string,
) error {
	tx, err := u.db.BeginTx(context.Background(), nil)
	if err != nil {
		fmt.Println("Error getting txn object", err)
	}
	defer tx.Rollback()

	ctx := context.WithValue(context.Background(), "txn", tx)
	err = u.pbr.UpdateProgress(ctx, []playbackrepository.ProgressUpdate{
		{
			UserId:    userId,
			MediaId:   movieId,
			ProfileId: profileId,
			Progress:  100,
			IsWatched: true,
		},
	})
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = u.pbr.UpdateWatched(ctx, []playbackrepository.ProgressUpdate{
		{
			UserId:    userId,
			MediaId:   movieId,
			ProfileId: profileId,
			Progress:  100,
			IsWatched: true,
		},
	})
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	err = tx.Commit()
	if err != nil {
		fmt.Println("Error comitting transaction", err)
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) MarkShowWatched(
	userId int,
	profileId int,
	showId string,
) error {
	tx, err := u.db.BeginTx(context.Background(), nil)
	if err != nil {
		fmt.Println("Error getting txn object", err)
	}
	defer tx.Rollback()

	show, err := u.tmdbUC.GetShowDetails(showId, at)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	var progressInput []playbackrepository.ProgressUpdate

	completelyWatched := true

	for _, v := range show.Seasons {
		if v.SeasonNumber == 0 {
			continue
		}
		for _, e := range v.Episodes {
			if e.EpisodeNumber == 0 {
				continue
			}
			date, err := time.Parse(layout, e.AirDate)
			if err != nil {
				fmt.Println("Error parsing episode date", err)
			}
			notReleased := date.UTC().Compare(time.Now().UTC()) == 1
			if notReleased {
				completelyWatched = false
				continue
			}
			temp := playbackrepository.ProgressUpdate{
				ProfileId: profileId,
				UserId:    userId,
				MediaId:   fmt.Sprintf("%s:%d:%d", showId, v.SeasonNumber, e.EpisodeNumber),
				Progress:  100,
				IsWatched: true,
			}

			progressInput = append(progressInput, temp)
		}
	}

	ctx := context.WithValue(context.Background(), "txn", tx)
	err = u.pbr.UpdateProgress(ctx, progressInput)
	if err != nil {
		fmt.Println("Error comitting transaction", err)
		return apperrors.SomethingWentWrongError{}
	}

	if completelyWatched {
		err = u.pbr.UpdateWatched(ctx, []playbackrepository.ProgressUpdate{
			{
				UserId:    userId,
				MediaId:   showId,
				ProfileId: profileId,
				Progress:  100,
				IsWatched: true,
			},
		})
		if err != nil {
			fmt.Println("Error comitting transaction", err)
			return apperrors.SomethingWentWrongError{}
		}

	}
	err = tx.Commit()
	if err != nil {
		fmt.Println("Error comitting transaction", err)
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) MarkSeasonWatched(
	userId int,
	profileId int,
	showId string,
	season int,
) error {
	tx, err := u.db.BeginTx(context.Background(), nil)
	if err != nil {
		fmt.Println("Error getting txn object", err)
	}
	defer tx.Rollback()

	show, err := u.tmdbUC.GetShowDetails(showId, at)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	var progressInput []playbackrepository.ProgressUpdate

	// TODO: Add support for season tracking so we can mark show watched based on season watched
	completelyWatched := false

	for _, v := range show.Seasons {
		if v.SeasonNumber == int64(season) {
			continue
		}
		for _, e := range v.Episodes {
			if e.EpisodeNumber == 0 {
				continue
			}
			date, err := time.Parse(layout, e.AirDate)
			if err != nil {
				fmt.Println("Error parsing episode date", err)
			}
			notReleased := date.UTC().Compare(time.Now().UTC()) == 1
			if notReleased {
				completelyWatched = false
				continue
			}
			temp := playbackrepository.ProgressUpdate{
				ProfileId: profileId,
				UserId:    userId,
				MediaId:   fmt.Sprintf("%s:%d:%d", showId, v.SeasonNumber, e.EpisodeNumber),
				Progress:  100,
				IsWatched: true,
			}

			progressInput = append(progressInput, temp)
		}
	}

	if len(progressInput) < 0 {
		fmt.Println("No episodes found")
		return nil
	}

	ctx := context.WithValue(context.Background(), "txn", tx)
	err = u.pbr.UpdateProgress(ctx, progressInput)
	if err != nil {
		fmt.Println("Error comitting transaction", err)
		return apperrors.SomethingWentWrongError{}
	}

	if completelyWatched {
		err = u.pbr.UpdateWatched(ctx, []playbackrepository.ProgressUpdate{
			{
				UserId:    userId,
				MediaId:   showId,
				ProfileId: profileId,
				Progress:  100,
				IsWatched: true,
			},
		})
		if err != nil {
			fmt.Println("Error comitting transaction", err)
			return apperrors.SomethingWentWrongError{}
		}

	}
	err = tx.Commit()
	if err != nil {
		fmt.Println("Error comitting transaction", err)
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}
