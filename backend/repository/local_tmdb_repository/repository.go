package localtmdbrepository

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"time"
	"zxy/models"

	"github.com/lib/pq"
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
      data || jsonb_build_object('imdb_rating', r.average_rating)
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
      data || jsonb_build_object('imdb_rating', r.average_rating)
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
  defer rows.Close()
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
  defer rows.Close()
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

func (r *Repository) GetLibrary(filter models.LibraryFilter) ([]models.ZxyMedia, int, error) {
	var res []models.ZxyMedia
	var count int
	format := "2006-01-02"
	query := `
  select data,imdb_rating from details
  `
	countQuery := `
  select count(*) from details
  `
	suffix := " where type = $1 and is_adult = false "

	tp := "show"
	if filter.IsMovie {
		tp = "movie"
	}

	var params []any
	var countParams []any

	params = append(params, tp)
	cTime := time.Now()
	if filter.ThisWeek {
		startTime := cTime.AddDate(0, 0, -7).Format(format)
		if filter.IsMovie {
			suffix += fmt.Sprintf(
				" and release_date >= $%d and release_date <= $%d",
				len(params)+1,
				len(params)+2,
			)
			params = append(params, startTime, cTime.Format(format))
		} else {
			if filter.IsFirstAir {
				suffix += fmt.Sprintf(" and first_air_date >= $%d and first_air_date <= $%d", len(params)+1, len(params)+2)
				params = append(params, startTime, cTime.Format(format))
			} else {
				suffix += fmt.Sprintf(" and last_air_date >= $%d and last_air_date <= $%d", len(params)+1, len(params)+2)
				params = append(params, startTime, cTime.Format(format))
			}
		}
	}

	if filter.ThisMonth {
		startTime := cTime.AddDate(0, 0, -30).Format(format)
		if filter.IsMovie {
			suffix += fmt.Sprintf(
				" and release_date >= $%d and release_date <= $%d",
				len(params)+1,
				len(params)+2,
			)
			params = append(params, startTime, cTime.Format(format))
		} else {
			if filter.IsFirstAir {
				suffix += fmt.Sprintf(" and first_air_date >= $%d and first_air_date <= $%d", len(params)+1, len(params)+2)
				params = append(params, startTime, cTime.Format(format))
			} else {
				suffix += fmt.Sprintf(" and last_air_date >= $%d and last_air_date <= $%d", len(params)+1, len(params)+2)
				params = append(params, startTime, cTime.Format(format))
			}
		}
	}

	for i, v := range filter.Years {
		if i == 0 {
			suffix += " and ( "
		} else {
			suffix += " or "

		}
		firstDay := time.Date(v, time.January, 1, 0, 0, 0, 0, cTime.Location()).Format(format)
		lastDay := time.Date(v, time.December, 31, 0, 0, 0, 0, cTime.Location()).Format(format)
		if filter.IsMovie {
			suffix += fmt.Sprintf(
				" (release_date >= $%d and release_date <= $%d) ",
				len(params)+1,
				len(params)+2,
			)
			params = append(params, firstDay, lastDay)
		} else {
			if filter.IsFirstAir {
				suffix += fmt.Sprintf(" (first_air_date >= $%d and first_air_date <= $%d) ", len(params)+1, len(params)+2)
				params = append(params, firstDay, lastDay)
			} else {
				suffix += fmt.Sprintf(" (last_air_date >= $%d and last_air_date <= $%d) ", len(params)+1, len(params)+2)
				params = append(params, firstDay, lastDay)
			}
		}
		if i == len(filter.Years)-1 {
			suffix += " ) "
		}
	}

	if len(filter.Language) != 0 {
		suffix += fmt.Sprintf(" and language = $%d", len(params)+1)
		params = append(params, filter.Language)
	}

	if filter.ImdbRating > 0 {
		suffix += fmt.Sprintf(" and imdb_rating >= $%d", len(params)+1)
		params = append(params, filter.ImdbRating)
	}

	var excludeGenre string
	var includeGenre string

	for i, v := range filter.IncludedGenres {
		if i == 0 {
			includeGenre += "array["
		}
		if i > 0 && i < len(includeGenre)-1 {
			includeGenre += ","
		}
		includeGenre += fmt.Sprintf("%d", v)
		if i == len(filter.IncludedGenres)-1 {
			includeGenre += "]"
		}
	}

	for i, v := range filter.ExcludedGenres {
		if i == 0 {
			excludeGenre += "array["
		}
		if i > 0 && i < len(excludeGenre)-1 {
			excludeGenre += ","
		}
		excludeGenre += fmt.Sprintf("%d", v)
		if i == len(filter.ExcludedGenres)-1 {
			excludeGenre += "]"
		}
	}

	if len(includeGenre) != 0 {
		suffix += fmt.Sprintf(" and genre_ids && %s", includeGenre)
	}

	if len(excludeGenre) != 0 {
		suffix += fmt.Sprintf(" and not genre_ids && %s", excludeGenre)
	}

	// suffix += " and imdb_votes > 100000"

	if filter.MinVotes > 0 {
		suffix += fmt.Sprintf(" and imdb_votes > $%d", len(params)+1)
		params = append(params, filter.MinVotes)
	}

	countQuery += suffix
	countParams = append(countParams, params...)

	order := "asc"
	if !filter.IsAsc {
		order = "desc"
	}

	sort := filter.Sort

	if sort == "date" {
		if filter.IsMovie {
			sort = "release_date"
		} else {
			if filter.IsFirstAir {
				sort = "first_air_date"
			} else {
				sort = "last_air_date"
			}
		}
	}
	suffix += fmt.Sprintf(" order by %s %s NULLS LAST", sort, order)
	// params = append(params, sort, order)

	items := filter.Items
	if items == 0 {
		items = 10
	}
	suffix += fmt.Sprintf(" limit $%d", len(params)+1)
	params = append(params, items)

	page := filter.Page
	if page == 0 {
		page = 1
	}
	suffix += fmt.Sprintf(" offset $%d", len(params)+1)
	params = append(params, (page-1)*items)

	query += suffix

	row := r.db.QueryRow(countQuery, countParams...)
	err := row.Scan(&count)
	if err != nil {
		fmt.Println("Error scanning count in movies query", err)
		return res, count, err
	}

	fmt.Println(params...)

	rows, err := r.db.Query(query, params...)
  defer rows.Close()
	if err != nil {
		fmt.Println("Error in movies query", err)
		return res, count, err
	}
	for rows.Next() {
		var temp models.ZxyMedia
		var jsn json.RawMessage
		var rating float64
		var rtg sql.NullFloat64
		err := rows.Scan(&jsn, &rtg)
		if err != nil {
			fmt.Println("Error scanning movies", err)
			return res, count, err
		}

		err = json.Unmarshal(jsn, &temp)
		if err != nil {
			fmt.Println("Error unmarshalling movies", err)
			return res, count, err
		}
		if rtg.Valid {
			rating = rtg.Float64
		}
		temp.ImdbRating = rating

		res = append(res, temp)
	}

	return res, count, nil
}

func (r *Repository) GetLibraryFromIds(tmdbId []int, tp string) ([]models.ZxyMedia, error) {
	var res []models.ZxyMedia
	query := `
  select  data, imdb_rating, genre_ids from details where tmdb_id in (
  `
	for i, v := range tmdbId {
		query += fmt.Sprintf("%d", v)
		if i != len(tmdbId)-1 {
			query += ","
		}
	}
	query += ")"
	query += fmt.Sprintf("and type = '%s'", tp)

	rows, err := r.db.Query(query)
  defer rows.Close()
	if err != nil {
		fmt.Println("Error getting library from ids", err)
		return res, err
	}
	for rows.Next() {
		var jsn json.RawMessage
		var genreId []int64
		var rtg sql.NullFloat64
		var temp models.ZxyMedia
		err := rows.Scan(&jsn, &rtg, pq.Array(&genreId))
		if err != nil {
			fmt.Println("Error scanning library from id", err)
			return res, err
		}

		err = json.Unmarshal(jsn, &temp)
		if err != nil {
			fmt.Println("Error unmarshalling library from id", err)
			return res, err
		}
		if rtg.Valid {
			temp.ImdbRating = rtg.Float64
		}
		temp.GenreIDS = genreId
		res = append(res, temp)
	}

	return res, nil
}

func (r *Repository) GetLibraryFromIdsSameOrder(
	tmdbId []int,
	tp string,
) ([]models.ZxyMedia, error) {
	tempMap := make(map[int]models.ZxyMedia)
	res := []models.ZxyMedia{}
	query := `
  select  data, imdb_rating, genre_ids from details where tmdb_id in (
  `
	for i, v := range tmdbId {
		query += fmt.Sprintf("%d", v)
		if i != len(tmdbId)-1 {
			query += ","
		}
	}
	query += ")"
	query += fmt.Sprintf("and type = '%s'", tp)

	rows, err := r.db.Query(query)
  defer rows.Close()
	if err != nil {
		fmt.Println("Error getting library from ids", err)
		return res, err
	}
	for rows.Next() {
		var jsn json.RawMessage
		var genreId []int64
		var rtg sql.NullFloat64
		var temp models.ZxyMedia
		err := rows.Scan(&jsn, &rtg, pq.Array(&genreId))
		if err != nil {
			fmt.Println("Error scanning library from id", err)
			return res, err
		}

		err = json.Unmarshal(jsn, &temp)
		if err != nil {
			fmt.Println("Error unmarshalling library from id", err)
			return res, err
		}
		if rtg.Valid {
			temp.ImdbRating = rtg.Float64
		}
		temp.GenreIDS = genreId
		tempMap[int(temp.ID)] = temp
	}

	for _, v := range tmdbId {
		temp, ok := tempMap[v]
		if !ok {
			fmt.Println("Not found in db", v)
			continue
		}
    temp.Type = tp
		res = append(res, temp)
	}

	return res, nil
}
