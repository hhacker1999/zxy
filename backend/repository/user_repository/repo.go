package userrepository

import (
	"database/sql"
	"fmt"
	"time"
	"zxy/models"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{
		db: db,
	}
}

func (r *Repository) StoreTraktAuthToken(data models.TraktAuthRes) (*time.Time, error) {
	row := r.db.QueryRow("select trakt_logged_in_at from users where id = 1")
	var createdAtSql sql.NullTime
	var createdAt *time.Time

	err := row.Scan(&createdAtSql)
	if err != nil {
		fmt.Println("Error getting logged in time ", err)
		return nil, err
	}
	if createdAtSql.Valid {
		createdAt = &createdAtSql.Time
		createdAtSql.Value()
	}

	_, err = r.db.Exec(`
    insert into users expiry,
    trakt_refresh_token,
    trakt_auth_token,
    trakt_logged_in_at values($1, $2, $3, $4) where id = 1
    `, data.ExpiresIn, data.RefreshToken, data.AccessToken, data.CreatedAt)
	if err != nil {
		fmt.Println("Error inserting trakt auth token ", err)
	}

	return createdAt, err
}
