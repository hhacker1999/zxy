package progressusecase

import (
	"context"
	"database/sql"
	"fmt"
	"strconv"
	"strings"
	"time"
	apperrors "zxy/app_errors"
	"zxy/models"
	playbackrepository "zxy/repository/playback_repository"
	tmdbusecase "zxy/usecase/tmdb_usecase"
)

const layout = "2006-01-02"
const continueWatchingThreshold = 90.00

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

	watched := false
	visible := true
	res, err := u.pbr.GetProgressMultiple(
		userId,
		profileId,
		"",
		false,
		0,
		0,
		&watched,
		&visible,
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
		nil,
		nil,
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

	watched := progress > continueWatchingThreshold
	splitted := strings.Split(mediaId, ":")
	if len(splitted) == 1 {
		err := u.pbr.UpdateProgress(context.Background(), []playbackrepository.ProgressUpdate{
			{
				UserId:    userId,
				MediaId:   mediaId,
				ProfileId: profileId,
				Progress:  progress,
				IsWatched: watched,
			},
		})
		return err
	}

	err := u.pbr.UpdateProgress(context.Background(), []playbackrepository.ProgressUpdate{
		{
			UserId:    userId,
			MediaId:   mediaId,
			ProfileId: profileId,
			Progress:  progress,
			IsWatched: watched,
		},
	})
	if !watched {
		return nil
	}

	show, err := u.tmdbUC.GetShowDetails(splitted[0])
	if err != nil {
		fmt.Println("Unable to get show details for next episodes", err)
		return nil
	}
	season, err := strconv.Atoi(splitted[1])
	if err != nil {
		fmt.Println("Invalid season number", splitted[1])
		return nil
	}
	episode, err := strconv.Atoi(splitted[2])
	if err != nil {
		fmt.Println("Invalid episode number", splitted[2])
		return nil
	}

	// showProgress, err := u.GetShowProgress(userId, profileId, splitted[0])
	// if err != nil {
	// 	return nil
	// }
	// mp := make(map[string]bool)
	// for _, v := range showProgress {
	// 	mp[v.MediaId] = v.IsWatched
	// }

	for si, v := range show.Seasons {
		if v.SeasonNumber == int64(season) {
			for ei, e := range v.Episodes {
				if e.EpisodeNumber == int64(episode) {
					u.setContinueWatchingForNextEpisode(
						show,
						splitted[0],
						userId,
						profileId,
						si,
						ei,
					)
				}
			}
		}
	}

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

	show, err := u.tmdbUC.GetShowDetails(showId)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	var progressInput []playbackrepository.ProgressUpdate

	// completelyWatched := true

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
				// completelyWatched = false
				continue
			}
			temp := playbackrepository.ProgressUpdate{
				ProfileId: profileId,
				UserId:    userId,
				MediaId:   fmt.Sprintf("%s:%d:%d", showId, v.SeasonNumber, e.EpisodeNumber),
				Progress:  0,
				IsWatched: true,
			}

			progressInput = append(progressInput, temp)
		}
	}

	ctx := context.WithValue(context.Background(), "txn", tx)
	err = u.pbr.UpdateWatched(ctx, progressInput)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	// if completelyWatched {
	// 	err = u.pbr.UpdateWatched(ctx, []playbackrepository.ProgressUpdate{
	// 		{
	// 			UserId:    userId,
	// 			MediaId:   showId,
	// 			ProfileId: profileId,
	// 			Progress:  100,
	// 			IsWatched: true,
	// 		},
	// 	})
	// 	if err != nil {
	// 		fmt.Println("Error comitting transaction", err)
	// 		return apperrors.SomethingWentWrongError{}
	// 	}
	//
	// }
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

	show, err := u.tmdbUC.GetShowDetails(showId)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	var progressInput []playbackrepository.ProgressUpdate

	// TODO: Add support for season tracking so we can mark show watched based on season watched
	// completelyWatched := false
	var si int
	var ei int

	for is, v := range show.Seasons {
		if v.SeasonNumber != int64(season) {
			continue
		}
		for ie, e := range v.Episodes {
			if e.EpisodeNumber == 0 {
				continue
			}
			date, err := time.Parse(layout, e.AirDate)
			if err != nil {
				fmt.Println("Error parsing episode date", err)
			}
			notReleased := date.UTC().Compare(time.Now().UTC()) == 1
			if notReleased {
				// completelyWatched = false
				continue
			}
			temp := playbackrepository.ProgressUpdate{
				ProfileId: profileId,
				UserId:    userId,
				MediaId:   fmt.Sprintf("%s:%d:%d", showId, v.SeasonNumber, e.EpisodeNumber),
				Progress:  0,
				IsWatched: true,
			}

			progressInput = append(progressInput, temp)
			ei = ie
		}
		si = is
	}

	if len(progressInput) < 0 {
		fmt.Println("No episodes found")
		return nil
	}

	ctx := context.WithValue(context.Background(), "txn", tx)
	err = u.pbr.UpdateWatched(ctx, progressInput)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	u.setContinueWatchingForNextEpisode(show, showId, userId, profileId, si, ei)

	// if completelyWatched {
	// 	err = u.pbr.UpdateWatched(ctx, []playbackrepository.ProgressUpdate{
	// 		{
	// 			UserId:    userId,
	// 			MediaId:   showId,
	// 			ProfileId: profileId,
	// 			Progress:  100,
	// 			IsWatched: true,
	// 		},
	// 	})
	// 	if err != nil {
	// 		fmt.Println("Error comitting transaction", err)
	// 		return apperrors.SomethingWentWrongError{}
	// 	}
	//
	// }
	err = tx.Commit()
	if err != nil {
		fmt.Println("Error comitting transaction", err)
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}

func (u *Usecase) MarkEpisodeWatched(
	userId int,
	profileId int,
	showId string,
	season int,
	episode int,
) error {
	show, err := u.tmdbUC.GetShowDetails(showId)
	if err != nil {
		fmt.Println("Unable to get show details for next episodes", err)
		return nil
	}

	key := fmt.Sprintf("%s:%d:%d", showId, season, episode)
	err = u.pbr.UpdateWatched(context.Background(), []playbackrepository.ProgressUpdate{
		{
			UserId:    userId,
			MediaId:   key,
			ProfileId: profileId,
			IsWatched: true,
		},
	})

	for si, v := range show.Seasons {
		if v.SeasonNumber == int64(season) {
			for ei, e := range v.Episodes {
				if e.EpisodeNumber == int64(episode) {
					u.setContinueWatchingForNextEpisode(
						show,
						showId,
						userId,
						profileId,
						si,
						ei,
					)
				}
			}
		}
	}

	return err
}

func (u *Usecase) setContinueWatchingForNextEpisode(
	show models.TMDBShow,
	id string,
	userId int,
	profileId int,
	si int,
	ei int,
) error {

	showProgress, err := u.GetShowProgress(userId, profileId, id)
	if err != nil {
		return nil
	}
	mp := make(map[string]bool)
	for _, v := range showProgress {
		mp[v.MediaId] = v.IsWatched
	}

	sIndex := si
	eIndex := ei + 1
	// NOTE: Bound checks
	v := show.Seasons[si]
	if eIndex == len(v.Episodes) {
		eIndex = 0
		sIndex += 1
		if sIndex == len(show.Seasons) {
			return nil
		}
	}
sess:
	for sIndex < len(show.Seasons) {
		ses := show.Seasons[sIndex]
	epis:
		for eIndex < len(ses.Episodes) {
			epi := ses.Episodes[eIndex]
			key := fmt.Sprintf(
				"%s:%d:%d",
				id,
				ses.SeasonNumber,
				epi.EpisodeNumber,
			)
			watched, ok := mp[key]
			if ok {
				if watched {
					eIndex += 1
					continue epis
				}
				return nil
			} else {
				u.UpdatePlaybackProgress(userId, profileId, key, 0)
				return nil
			}
		}
		sIndex += 1
		continue sess
	}
	return nil
}

func (u *Usecase) RemoveFromContinueWatching(
	userId int,
	profileId int,
	mediaId string,
) error {
	err := u.pbr.UpdateProgressVisible(context.Background(), userId, profileId, mediaId)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	return nil
}
