package userrepository

import (
	"fmt"
	"zxy/models"
)

func (r *Repository) AddToLibrary(profileId int, tmdbId int, tp string) error {
	_, err := r.db.Exec(
		`insert into profile_library (profile_id, tmdb_id, type) values ($1, $2, $3)`,
		profileId,
		tmdbId,
		tp,
	)
	if err != nil {
		fmt.Println("Error inserting into library", err)
	}

	return err
}

func (r *Repository) RemoveFromLibrary(profileId int, tmdbId int, tp string) error {
	_, err := r.db.Exec(
		`delete from profile_library where profile_id = $1 and tmdb_id = $2 and type = $3`,
		profileId,
		tmdbId,
		tp,
	)
	if err != nil {
		fmt.Println("Error deleting from library", err)
	}

	return err
}

func (r *Repository) GetUserLibrary(
	profileId int,
	page int,
	items int,
) ([]models.TmdbMediaIdentity, int, error) {
	var res []models.TmdbMediaIdentity

	countPrefix := "select count(*) "
	queryPrefix := "select tmdb_id, type "
	query := " from profile_library where profile_id = $1 "
  offset:= int((items*(page-1)))
	limits := fmt.Sprintf(" order by created_at desc limit %d offset %d ", items, offset)

	row := r.db.QueryRow(
		countPrefix+query,
		profileId,
	)
	var count int
	err := row.Scan(&count)
	if err != nil {
		fmt.Println("Error scanning library count", err)
		return res, 0, err
	}

	rows, err := r.db.Query(queryPrefix+query+limits, profileId)
	defer rows.Close()
	if err != nil {
		fmt.Println("Error making get library query", err)
		return res, 0, err
	}

	for rows.Next() {
		var temp models.TmdbMediaIdentity
		err = rows.Scan(&temp.TmdbId, &temp.Type)
		if err != nil {
			fmt.Println("Error scanning get library response", err)
			return res, 0, err
		}
		res = append(res, temp)
	}

	return res, count, nil
}
