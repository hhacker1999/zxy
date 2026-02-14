package playbackrepository

import (
	"context"
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

func (r *Repository) UpdateProgress(ctx context.Context, updates []ProgressUpdate) error {
	if len(updates) == 0 {
		return nil
	}

	query := `
  insert into watch_progress (user_id, profile_id, media_id, progress, is_watched) values 
  `
	params := []any{}

	for i, v := range updates {
		ln := len(params)
		query += fmt.Sprintf("( $%d, $%d, $%d, $%d, $%d )", ln+1, ln+2, ln+3, ln+4, ln+5)
		params = append(params, v.UserId, v.ProfileId, v.MediaId, v.Progress, v.IsWatched)
		if i != len(updates)-1 {
			query += ", "
		}

	}

	query += `on conflict (user_id, media_id, profile_id) do update set updated_at = NOW(), progress = excluded.progress, is_watched = excluded.is_watched`

	var err error
	tx, ok := ctx.Value("txn").(*sql.Tx)
	if ok {
		_, err = tx.Exec(query, params...)
	} else {
		_, err = r.db.Exec(query, params...)
	}

	if err != nil {
		fmt.Println("Error updating watch progress")
	}

	return err
}

func (r *Repository) UpdateWatched(ctx context.Context, updates []ProgressUpdate) error {
	if len(updates) == 0 {
		return nil
	}

	query := `
  insert into watch_progress (user_id, profile_id, media_id, is_watched, progress) values 
  `
	params := []any{}

	for i, v := range updates {
		ln := len(params)
		query += fmt.Sprintf("( $%d, $%d, $%d, true ,0)", ln+1, ln+2, ln+3)
		params = append(params, v.UserId, v.ProfileId, v.MediaId)
		if i != len(updates)-1 {
			query += ", "
		}

	}

	query += `on conflict (user_id, media_id, profile_id) do update set is_watched = true, updated_at = now()`

	var err error
	tx, ok := ctx.Value("txn").(*sql.Tx)
	if ok {
		_, err = tx.Exec(query, params...)
	} else {
		_, err = r.db.Exec(query, params...)
	}

	if err != nil {
		fmt.Println("Error updating watched", err)
	}

	return err
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

func (r *Repository) GetProgress(
	userId int,
	profileId int,
	mediaId string,
) (ProgressUpdate, error) {
	var res ProgressUpdate
	row := r.db.QueryRow(
		`select user_id, profile_id, media_id, progress, is_watched, created_at, updated_at from watch_progress where
    user_id = $1 and  profile_id = $2 and media_id = $3
    `,
		userId,
		profileId,
		mediaId,
	)

	err := row.Scan(
		&res.UserId,
		&res.ProfileId,
		&res.MediaId,
		&res.Progress,
		&res.IsWatched,
		&res.CreatedAt,
		&res.UpdatedAt,
	)
	if err != nil {
		fmt.Println("Error getting progress", err)
	}

	return res, err
}

func (r *Repository) GetProgressMultiple(
	userId int,
	profileId int,
	mediaId string,
	isShow bool,
	progressLte float64,
	progressGte float64,
	isWatched *bool,
	isVisible *bool,
) ([]ProgressUpdate, error) {
	var res []ProgressUpdate
	query := `
		select user_id, profile_id, media_id, progress, is_watched, updated_at, created_at from watch_progress where
    user_id = $1 and  profile_id = $2
`
	params := []any{}
	params = append(params, userId, profileId)

	if len(mediaId) != 0 {
		if isShow {
			query += fmt.Sprintf(" and media_id like '%s:%%'", mediaId)
		} else {
			query += " and media_id = $3"
			params = append(params, mediaId)
		}
	}

	if progressLte != 0 {
		query += fmt.Sprintf(" and progress <= %.2f", progressLte)
	}
	if progressGte != 0 {
		query += fmt.Sprintf(" and progress >= %.2f", progressGte)
	}

	if isWatched != nil {
		query += fmt.Sprintf(" and is_watched = %t", *isWatched)
	}
	if isVisible != nil {
		query += fmt.Sprintf(" and visible = %t", *isVisible)
	}

	query += " order by updated_at desc"

	rows, err := r.db.Query(
		query, params...,
	)
	if err != nil {
		fmt.Println("Error getting multiple progress", err)
		return nil, err
	}

	for rows.Next() {
		var temp ProgressUpdate
		err = rows.Scan(
			&temp.UserId,
			&temp.ProfileId,
			&temp.MediaId,
			&temp.Progress,
			&temp.IsWatched,
			&temp.UpdatedAt,
			&temp.CreatedAt,
		)
		if err != nil {
			fmt.Println("Error scanning progress", err)
			return nil, err
		}
		res = append(res, temp)
	}

	return res, err
}

func (r *Repository) DeleteProfileProgress(ctx context.Context, userId int, profileId int) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	if ok {
		_, err = txn.Exec(
			`delete from watch_progress where profile_id = $1 and user_id = $2`,
			profileId,
			userId,
		)
	} else {
		_, err = r.db.Exec(
			`delete from watch_progress where profile_id = $1 and user_id = $2`,
			profileId,
			userId,
		)
	}
	if err != nil {
		fmt.Println("Error deleting profile watch progress", err)
	}

	return err
}
