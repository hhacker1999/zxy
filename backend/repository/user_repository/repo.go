package userrepository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"
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

func (r *Repository) GetUserFromEmail(email string) (models.User, error) {
	var res models.User
	row := r.db.QueryRow(`
    select
      u.id,
      u.user_id,
      email,
      u.name,
      u.created_at,
      u.updated_at,
      pwd_hash,
      json_agg(
        jsonb_build_object('name', up.name, 'pin_hash',up.pin_hash, 'id', up.id)
      )
    from
      users u
      left join user_profiles up on (u.id = up.user_id)
    where
      email = $1
    group by
      u.id,
      u.email,
      u.user_id,
      u.created_at,
      u.updated_at,
      u.pwd_hash;
    `, email)

	var profile []byte
	err := row.Scan(
		&res.Id,
		&res.UserId,
		&res.Email,
		&res.Name,
		&res.CreatedAt,
		&res.UpdatedAt,
		&res.PwdHash,
		&profile,
	)
	if err != nil {
		fmt.Println("Error getting user from email ", err)
		return res, err
	}

	err = json.Unmarshal(profile, &res.Profiles)
	if err != nil {
		fmt.Println("Error unmarshalling user profiles", err)
	}

	return res, err
}

func (r *Repository) GetUserFromUserId(userId string) (models.User, error) {
	var res models.User
	row := r.db.QueryRow(`
    select
      id,
      user_id,
      email,
      name,
      created_at,
      updated_at,
      pwd_hash,
      json_agg(
        jsonb_build_object('name', up.name, 'pin_hash',up.pin_hash, 'id', up.id)
      )
    from
      users u
      left join user_profiles up on (u.id = up.user_id)
    where
      user_id = $1
    group by
      email,
      user_id,
      create_at,
      updated_at,
      pwd_hash;
    `, userId)

	var profile []byte
	err := row.Scan(
		&res.Id,
		&res.UserId,
		&res.Email,
		&res.Name,
		&res.CreatedAt,
		&res.UpdatedAt,
		&res.PwdHash,
		&profile,
	)
	if err != nil {
		fmt.Println("Error getting user from user id ", err)
		return res, err
	}

	err = json.Unmarshal(profile, &res.Profiles)
	if err != nil {
		fmt.Println("Error unmarshalling user profiles", err)
	}

	return res, err
}

func (r *Repository) GetUserFromId(userId int) (models.User, error) {
	var res models.User
	row := r.db.QueryRow(`
    select
      u.id,
      u.user_id,
      u.email,
      u.name,
      u.created_at,
      u.updated_at,
      u.pwd_hash,
      json_agg(
        jsonb_build_object('name', up.name, 'pin_hash',up.pin_hash, 'id', up.id)
      )
    from
      users u
      left join user_profiles up on (u.id = up.user_id)
    where
      u.id = $1
    group by
      u.id,
      u.email,
      u.user_id,
      u.created_at,
      u.updated_at,
      u.pwd_hash;
    `, userId)

	var profile []byte
	err := row.Scan(
		&res.Id,
		&res.UserId,
		&res.Email,
		&res.Name,
		&res.CreatedAt,
		&res.UpdatedAt,
		&res.PwdHash,
		&profile,
	)
	if err != nil {
		fmt.Println("Error getting user from id ", err)
		return res, err
	}

	err = json.Unmarshal(profile, &res.Profiles)
	if err != nil {
		fmt.Println("Error unmarshalling user profiles", err)
	}

	return res, err
}

func (r *Repository) CreateUser(ctx context.Context, user models.User) (int, error) {
	query :=
		`insert into users (user_id, name, email, pwd_hash) values($1, $2, $3, $4) returning id`
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var row *sql.Row
	if ok {
		row = txn.QueryRow(query, user.UserId, user.Name, user.Email, user.PwdHash)
	} else {
		row = r.db.QueryRow(query, user.UserId, user.Name, user.Email, user.PwdHash)
	}
	var res int
	err := row.Scan(&res)
	if err != nil {
		fmt.Println("Error inserting into user ", err)
	}

	return res, err
}

func (r *Repository) CreateUserProfile(ctx context.Context, profile models.UserProfile) error {
	query :=
		`insert into user_profiles (user_id, name, pin_hash) values($1, $2, $3)`
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	if ok {
		_, err = txn.Exec(query, profile.UserId, profile.Name, profile.PinHash)
	} else {
		_, err = r.db.Exec(query, profile.UserId, profile.Name, profile.PinHash)
	}
	if err != nil {
		fmt.Println("Error inserting into user profiles ", err)
	}

	return err
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
