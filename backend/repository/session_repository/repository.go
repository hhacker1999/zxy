package sessionrepository

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

func (r *Repository) CreateUserSession(session models.Session) error {
	_, err := r.db.Exec(
		`insert into sessions (user_id, token, expiry) values($1, $2, $3)`,
		session.UserId,
		session.Token,
		session.Expiry,
	)
	if err != nil {
		fmt.Println("Error storing user session", err)
	}

	return err
}

func (r *Repository) GetUserSession(token string) (models.Session, error) {
	var res models.Session
	row := r.db.QueryRow(
		`select id, user_id, token, expiry from sessions where token = $1`,
		token,
	)
	err := row.Scan(&res.Id, &res.UserId, &res.Token, &res.Expiry)
	if err != nil {
		fmt.Println("Error getting user session", err)
	}

	return res, err
}

func (r *Repository) GetUserSessionFromId(sessionId int) (models.Session, error) {
	var res models.Session
	row := r.db.QueryRow(
		`select id, user_id, token, expiry from sessions where id = $1`,
		sessionId,
	)
	err := row.Scan(&res.Id, &res.UserId, &res.Token, &res.Expiry)
	if err != nil {
		fmt.Println("Error getting user session", err)
	}

	return res, nil
}

func (r *Repository) CreateProfileSession(session models.ProfileSession) error {
	_, err := r.db.Exec(
		`insert into profile_sessions (session_id, token, expiry, refresh_token, profile_id) values($1, $2, $3, $4, $5)`,
		session.SessionId,
		session.Token,
		session.Expiry,
		session.RefreshToken,
		session.ProfileId,
	)
	if err != nil {
		fmt.Println("Error storing profile session", err)
	}

	return err
}

func (r *Repository) GetProfileSession(token string) (models.ProfileSession, error) {
	var res models.ProfileSession
	row := r.db.QueryRow(
		`select id, profile_id, session_id, token, expiry, refresh_token from sessions where token = $1`,
		token,
	)
	err := row.Scan(&res.Id, &res.ProfileId, &res.SessionId, &res.Token, &res.Expiry, &res.RefreshToken)
	if err != nil {
		fmt.Println("Error getting profile session", err)
	}

	return res, nil
}
