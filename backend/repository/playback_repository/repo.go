package playbackrepository

import (
	"database/sql"
	"fmt"
	"zxy/models"
)

type Repository struct {
	db *sql.DB
}

func New(db *sql.DB) *Repository {
	return &Repository{
		db: db,
	}
}

func (r *Repository) InserTraktMoviePlaybackHistory(items []models.TraktPlaybackHistoryItem) error {
	prefix := `
    insert into movie_progress user_id, movie_id, progress, is_watched
    values
  `
	args := []any{}

	for _, v := range items {
		argsLen := len(args)
		if argsLen != 0 {
			prefix += ","
		}
		prefix += fmt.Sprintf(" ($%d, $%d, $%d, $%d)", argsLen+1, argsLen+2, argsLen+3, argsLen+4)
		args = append(args, 1, v.Movie.IDS.Tmdb, 100.00, true)
	}

	suffix := ` on conflict(user_id, movie_id)
    do update set
    progress = 100.00,
    is_watched = true,
    updated_at = now()
`
	_, err := r.db.Exec(prefix+suffix, args...)
	if err != nil {
		fmt.Println("Error inserting movie playback history ", err)
	}

	return err
}

func (r *Repository) InsertTraktSeriesPlaybackHistory(items []models.TraktPlaybackHistoryItem) error {
	prefix := `
    insert into movie_progress user_id, series_id, season, episode, progress, is_watched
    values
  `
	args := []any{}

	for _, show := range items {
		argsLen := len(args)
		if argsLen != 0 {
			prefix += ","
		}
		for _, season := range show.Seasons {
			for _, episode := range season.Episodes {
				prefix += fmt.Sprintf(
					" ($%d, $%d, $%d, $%d, $%d, $%d)",
					argsLen+1,
					argsLen+2,
					argsLen+3,
					argsLen+4,
					argsLen+5,
					argsLen+6,
				)
				args = append(
					args,
					1,
					show.Show.IDS.Tmdb,
					season.Number,
					episode.Number,
					100.00,
					true,
				)
			}
		}
	}

	suffix := ` on conflict(user_id, series_id, season, episode)
    do update set
    progress = 100.00,
    is_watched = true,
    updated_at = now()
`
	_, err := r.db.Exec(prefix+suffix, args...)
	if err != nil {
		fmt.Println("Error inserting movie playback history ", err)
	}

	return err
}
