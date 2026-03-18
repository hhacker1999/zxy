package traktusecase

import (
	"context"
	"fmt"
	"strconv"
	"sync"
	apperrors "zxy/app_errors"
	"zxy/models"
	playbackrepository "zxy/repository/playback_repository"
)

func (u *Usecase) syncTraktData(userId int, profileId int, token string) error {
	movies := []models.TraktPlaybackHistoryItem{}
	series := []models.TraktPlaybackHistoryItem{}
	var merr error
	var serr error
	wg := sync.WaitGroup{}

	fmt.Println("Getting data from trakt for watched")
	wg.Add(2)
	go func() {
		defer wg.Done()
		movies, merr = u.getWatchedMovies(token)
	}()
	go func() {
		defer wg.Done()
		series, serr = u.getWatchedSeries(token)
	}()
	wg.Wait()
	fmt.Println("Got data from trakt for history")

	if merr != nil {
		return merr
	}
	if serr != nil {
		return serr
	}

	fmt.Println("No errors from trakt")

	isWatched := true
	watchedMedia, err := u.playbackRepo.GetProgressMultiple(
		userId,
		profileId,
		"",
		false,
		0,
		0,
		&isWatched,
		nil,
    0,
	)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}
	fmt.Println("Got watched movies")
	watchedMapMovies := make(map[int]struct{})
	watchedMapEpisodes := make(map[string]struct{})

	for _, v := range watchedMedia {
		tmdbId, err := strconv.Atoi(v.MediaId)
		if err != nil {
			watchedMapEpisodes[v.MediaId] = struct{}{}
			continue
		}
		watchedMapMovies[tmdbId] = struct{}{}
	}

	var toMarkWatched []playbackrepository.ProgressUpdate
	for _, v := range movies {
		if v.Movie.IDS.Tmdb == 0 {
			continue
		}
		_, ok := watchedMapMovies[int(v.Movie.IDS.Tmdb)]
		if !ok {
			toMarkWatched = append(
				toMarkWatched,
				playbackrepository.ProgressUpdate{
					MediaId:   fmt.Sprintf("%d", v.Movie.IDS.Tmdb),
					Progress:  0,
					IsWatched: true,
					UserId:    userId,
					ProfileId: profileId,
          UpdatedAt: v.LastWatchedAt,
				},
			)
		}
	}

	for _, v := range series {
		if v.Show.IDS.Tmdb == 0 {
			continue
		}
		for _, s := range v.Seasons {
			for _, e := range s.Episodes {
				key := fmt.Sprintf("%d:%d:%d", v.Show.IDS.Tmdb, s.Number, e.Number)
				_, ok := watchedMapEpisodes[key]
				if !ok {
					toMarkWatched = append(
						toMarkWatched,
						playbackrepository.ProgressUpdate{
							MediaId:   key,
							Progress:  0,
							IsWatched: true,
							UserId:    userId,
							ProfileId: profileId,
              UpdatedAt: v.LastWatchedAt,
						},
					)
				}
			}
		}
	}

	if len(toMarkWatched) == 0 {
		fmt.Println("Nothing to update in ZXY db")
	}
	if len(toMarkWatched) != 0 {
		err = u.playbackRepo.UpdateProgressTrakt(context.Background(), toMarkWatched)
	}

	isWatched = false
	incomplete, err := u.playbackRepo.GetProgressMultiple(
		userId,
		profileId,
		"",
		false,
		0,
		0,
		&isWatched,
		nil,
    0,
	)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	incompleteMap := make(map[string]playbackrepository.ProgressUpdate)
	for _, v := range incomplete {
		incompleteMap[v.MediaId] = v
	}

	data, err := u.getPlayback(token)
	if err != nil {
		return apperrors.SomethingWentWrongError{}
	}

	incomplete = []playbackrepository.ProgressUpdate{}

	for _, v := range data {
		if v.Type == "movie" {
			if v.Movie.IDS.Tmdb == 0 {
				continue
			}
			key := fmt.Sprintf("%d", v.Movie.IDS.Tmdb)
			progress, ok := incompleteMap[key]
			if ok {
				if progress.Progress < v.Progress {
					progress.Progress = v.Progress
					progress.UpdatedAt = v.PausedAt
					incomplete = append(incomplete, progress)
				}
			} else {
				incomplete = append(incomplete,
					playbackrepository.ProgressUpdate{
						Progress:  v.Progress,
						MediaId:   key,
						CreatedAt: v.PausedAt,
						UpdatedAt: v.PausedAt,
						ProfileId: profileId,
						UserId:    userId,
					})
			}

		}

		if v.Type == "episode" {
			if v.Show.IDS.Tmdb == 0 {
				continue
			}
			if v.Episode.Season == 0 || v.Episode.Number == 0 {
				continue
			}
			key := fmt.Sprintf("%d:%d:%d", v.Show.IDS.Tmdb, v.Episode.Season, v.Episode.Number)
			progress, ok := incompleteMap[key]
			if ok {
				if progress.Progress < v.Progress {
					progress.Progress = v.Progress
					progress.UpdatedAt = v.PausedAt
					incomplete = append(incomplete, progress)
				}
			} else {
				incomplete = append(incomplete,
					playbackrepository.ProgressUpdate{
						Progress:  v.Progress,
						MediaId:   key,
						CreatedAt: v.PausedAt,
						UpdatedAt: v.PausedAt,
						ProfileId: profileId,
						UserId:    userId,
					})
			}

		}
	}

	fmt.Println("Progress to update or create", len(incomplete))

	u.playbackRepo.UpdateProgressTrakt(context.Background(), incomplete)

	return nil
}
