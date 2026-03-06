package userrepository

import (
	"context"
	"database/sql"
	"fmt"
	"time"
	"zxy/models"
)

func (r *Repository) StoreTraktAuthToken(
	ctx context.Context,
	userId int,
	profileId int,
	data models.TraktAuthRes,
) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	if ok {
		_, err = txn.Exec(`
      update user_profiles set trakt_expiry = $1,
      trakt_refresh_token = $2,
      trakt_token = $3,
      is_trakt_valid = true where id = $4 and user_id = $5
      `, data.Expiry, data.RefreshToken, data.AccessToken, profileId, userId)
	} else {
		_, err = r.db.Exec(`
      update user_profiles set trakt_expiry = $1,
      trakt_refresh_token = $2,
      trakt_token = $3,
      is_trakt_valid = true where id = $4 and user_id = $5
      `, data.Expiry, data.RefreshToken, data.AccessToken, profileId, userId)
	}
	if err != nil {
		fmt.Println("Error inserting trakt auth token ", err)
	}

	return err
}

func (r *Repository) GetProfilesWithTraktExpiry(
	expiry time.Time,
) ([]models.ProfileTraktDetails, error) {
	var res []models.ProfileTraktDetails
	query := `
  select id, user_id, trakt_token, trakt_refresh_token, trakt_expiry
  from user_profiles where trakt_expiry < $1 and is_trakt_valid = true
  `
	rows, err := r.db.Query(query, expiry)
	if err != nil {
		fmt.Println("Error getting user trakt profiles", err)
		return res, err
	}
  defer rows.Close()
	for rows.Next() {
		var temp models.ProfileTraktDetails
		err = rows.Scan(
			&temp.ProfileId,
			&temp.UserId,
			&temp.Token,
			&temp.RefreshToken,
			&temp.Expiry,
		)
		if err != nil {
			fmt.Println("Error scanning profile trakt details", err)
			return res, err
		}
		res = append(res, temp)
	}

	return res, nil
}

func (r *Repository) SetTraktAuthInvalid(
	ctx context.Context,
	userId int,
	profileId int,
) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	if ok {
		_, err = txn.Exec(`
      update user_profiles set is_trakt_valid = false
      where id = $1 and user_id = $2
      `, profileId, userId)
	} else {
		_, err = r.db.Exec(`
      update user_profiles set is_trakt_valid = false
      where id = $1 and user_id = $2
      `, profileId, userId)
	}
	if err != nil {
		fmt.Println("Error setting trakt auth invalid ", err)
	}

	return err
}

func (r *Repository) RemoveTraktAuthToken(
	ctx context.Context,
	userId int,
	profileId int,
) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	if ok {
		_, err = txn.Exec(`
      update user_profiles set trakt_expiry = null,
      trakt_refresh_token = null,
      trakt_token = null,
      is_trakt_valid = null where id = $1 and user_id = $2
      `, profileId, userId)
	} else {
		_, err = r.db.Exec(`
      update user_profiles set trakt_expiry = null,
      trakt_refresh_token = null,
      trakt_token = null,
      is_trakt_valid = null where id = $1 and user_id = $2
      `, profileId, userId)
	}
	if err != nil {
		fmt.Println("Error removing trakt auth token ", err)
	}

	return err
}

func (r *Repository) GetUserTraktInfo(
	userId int, profileId int,
) (models.ProfileTraktDetails, error) {
	var res models.ProfileTraktDetails
	query := `
  select id, user_id, trakt_token, trakt_expiry, is_trakt_valid
  from user_profiles where user_id = $1 and id = $2
  `
	row := r.db.QueryRow(query, userId, profileId)
	tokenStr := sql.NullString{}
	expiry := sql.NullTime{}
	valid := sql.NullBool{}
	err := row.Scan(
		&res.ProfileId,
		&res.UserId,
		&tokenStr,
		&expiry,
		&valid,
	)
	if err != nil {
		fmt.Println("Error scanning profile trakt details", err)
		return res, err
	}
	if !expiry.Valid || !tokenStr.Valid || !valid.Valid {
		return res, sql.ErrNoRows
	}
	res.Expiry = expiry.Time
	res.Token = tokenStr.String
	res.IsTraktValid = valid.Bool

	return res, nil
}
