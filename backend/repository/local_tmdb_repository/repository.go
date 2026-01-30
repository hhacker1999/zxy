package localtmdbrepository

import (
	"database/sql"
	"encoding/json"
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

func (r *Repository) GetMovie(tmdbId int) (models.TMDBMovie, error) {
	var res models.TMDBMovie
	query := `
     select
      data || jsonb_build_object('imdb_ratings', r.average_rating)
    from
      details
      left join imdb_ratings r on (r.tconst = (data -> 'external_ids' ->> 'imdb_id'))
    where
      type = 'movie'
      and tmdb_id = $1
  `
	row := r.db.QueryRow(query, tmdbId)
	var jsn json.RawMessage
	err := row.Scan(&jsn)
	if err != nil {
		fmt.Println("Error scanning movie", err)
		return res, err
	}

	err = json.Unmarshal(jsn, &res)
	if err != nil {
		fmt.Println("Error unmarshalling movie", err)
		return res, err
	}

	return res, nil
}

func (r *Repository) GetShow(tmdbId int) (models.TMDBShow, error) {
	var res models.TMDBShow
	query := `
     select
      data || jsonb_build_object('imdb_ratings', r.average_rating)
    from
      details
      left join imdb_ratings r on (r.tconst = (data -> 'external_ids' ->> 'imdb_id'))
    where
      type = 'show'
      and tmdb_id = $1
  `
	row := r.db.QueryRow(query, tmdbId)
	var jsn json.RawMessage
	err := row.Scan(&jsn)
	if err != nil {
		fmt.Println("Error scanning show", err)
		return res, err
	}

	err = json.Unmarshal(jsn, &res)
	if err != nil {
		fmt.Println("Error unmarshalling show", err)
		return res, err
	}

	return res, nil
}

func (r *Repository) GetImdbRatings(imdbIds []string) (map[string]float64, error) {
	if len(imdbIds) == 0 {
		return nil, nil
	}

	res := make(map[string]float64)
	query := `
     select
      tconst,
      average_rating
    from
      imdb_ratings
      where tconst in (
  `
	params := []any{}
	for i, v := range imdbIds {
		query += fmt.Sprintf("$%d", len(params)+1)
		params = append(params, v)
		if i != len(imdbIds)-1 {
			query += ","
		}
	}
	query += ")"
	rows, err := r.db.Query(query, params...)
	if err != nil {
		if err == sql.ErrNoRows {
			return res, nil
		}
		fmt.Println("error getting imdb ratings", err)
		return res, err
	}

	for rows.Next() {
		var ratings float64
		var id string
		err = rows.Scan(&id, &ratings)
		if err != nil {
			fmt.Println("Error scanning row in imdb ratings", err)
			return res, err
		}
		res[id] = ratings
	}

	return res, nil
}

func (r *Repository) InsertDetails(tmdbId int, tp string, details any) error {
	data, err := json.Marshal(details)
	if err != nil {
		fmt.Println("Error marshalling details for storing in db", err)
		return err
	}

	query := `
  insert into details (type, tmdb_id, data) values($1, $2, $3) on conflict (tmdb_id, type)
  do update set data = excluded.data, updated_at = now()
  `
	_, err = r.db.Exec(query, tp, tmdbId, data)
	if err != nil {
		fmt.Println("Error inserting show/movie details", err)
	}

	return err
}
 
func (r *Repository) GetImdbRatingsFromTmdb(tmdbIds []int, tp string) (map[int]float64, error) {
	if len(tmdbIds) == 0 {
		return nil, nil
	}

	res := make(map[int]float64)
	query := `
  select tmdb_id, r.average_rating 
  from details inner join imdb_ratings r
  on (r.tconst = (data->'external_ids'->>'imdb_id'))
  where type = $1 and tmdb_id in (
  `
	params := []any{tp}
	for i, v := range tmdbIds {
		query += fmt.Sprintf("$%d", len(params)+1)
		params = append(params, v)
		if i != len(tmdbIds)-1 {
			query += ","
		}
	}
	query += ")"
	rows, err := r.db.Query(query, params...)
	if err != nil {
		if err == sql.ErrNoRows {
			return res, nil
		}
		fmt.Println("error getting imdb ratings", err)
		return res, err
	}

	for rows.Next() {
		var ratings float64
		var id int
		err = rows.Scan(&id, &ratings)
		if err != nil {
			fmt.Println("Error scanning row in imdb ratings", err)
			return res, err
		}
		res[id] = ratings
	}

	return res, nil
}
