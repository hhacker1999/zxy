package userrepository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
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
        jsonb_build_object('name', up.name, 'pin_hash',up.pin_hash, 'id', up.id, 'is_admin', up.is_admin, 'created_at', up.created_at)
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
        jsonb_build_object('name', up.name, 'pin_hash',up.pin_hash, 'id', up.id, 'is_admin', up.is_admin)
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
        jsonb_build_object('name', up.name, 'pin_hash',up.pin_hash, 'id', up.id, 'is_admin', up.is_admin, 'created_at', up.created_at)
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

func (r *Repository) CreateUserProfile(
	ctx context.Context,
	profile models.UserProfile,
) (int, error) {
	query :=
		`insert into user_profiles (user_id, name, pin_hash, is_admin, library_items) values($1, $2, $3, $4, $5) returning id`
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var row *sql.Row
	var err error
	items, err := json.Marshal(profile.LibraryItems)
	if err != nil {
		fmt.Println("Error marshalling library items", err)
		return 0, err
	}

	if ok {
		row = txn.QueryRow(
			query,
			profile.UserId,
			profile.Name,
			profile.PinHash,
			profile.IsAdmin,
			items,
		)
	} else {
		row = r.db.QueryRow(query, profile.UserId, profile.Name, profile.PinHash, profile.IsAdmin, items)
	}
	var id int
	err = row.Scan(&id)
	if err != nil {
		fmt.Println("Error inserting into user profiles ", err)
	}
	return id, err
}

func (r *Repository) GetUserProfile(
	ctx context.Context,
	userId int,
	profileId int,
) (models.UserProfile, map[string]string, []string, error) {
	var res models.UserProfile
	row := r.db.QueryRow(
		`select id, user_id, name, is_admin,pin_hash,library_items,
    trakt_expiry, is_trakt_valid, services, presets
    from user_profiles where user_id = $1 and id = $2`,
		userId,
		profileId,
	)

	var items *json.RawMessage
	var services *json.RawMessage
	var presets []string
	var traktExpiry sql.NullTime
	var isTraktValid sql.NullBool

	err := row.Scan(
		&res.Id,
		&res.UserId,
		&res.Name,
		&res.IsAdmin,
		&res.PinHash,
		&items,
		&traktExpiry,
		&isTraktValid,
		&services,
		pq.Array(&presets),
	)
	if err != nil {
		fmt.Println("Error getting user profile", err)
		return res, nil, nil, err
	}

	if traktExpiry.Valid {
		res.TraktExpiry = &traktExpiry.Time
	}

	if isTraktValid.Valid {
		res.TraktValid = isTraktValid.Bool
	}

	if items != nil {
		var lItems []models.ProfileLibraryItem
		err = json.Unmarshal(*items, &lItems)
		if err != nil {
			fmt.Println("Error unmarshalling library items", err)
			return res, nil, nil, err
		}
		res.LibraryItems = lItems
	}

	servicesMap := make(map[string]string)
	if services != nil {
		err = json.Unmarshal(*services, &servicesMap)
		if err != nil {
			fmt.Println("Error unmarshalling services", err)
			return res, nil, nil, err
		}
	}

	return res, servicesMap, presets, err
}

func (r *Repository) UpdateUserProfile(
	ctx context.Context,
	userId int,
	profileId int,
	name string,
	pinHash string,
) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	if ok {
		_, err = txn.Exec(
			`update user_profiles set name = $1, pin_hash = $2 where user_id = $3 and id = $4`,
			name,
			pinHash,
			userId,
			profileId,
		)
	} else {
		_, err = r.db.Exec(
			`update user_profiles set name = $1, pin_hash = $2 where user_id = $3 and id = $4`,
			name,
			pinHash,
			userId,
			profileId,
		)
	}
	if err != nil {
		fmt.Println("Error updating profile info", err)
	}

	return err
}

func (r *Repository) DeleteUser(
	ctx context.Context,
	userId int,
) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	if ok {
		_, err = txn.Exec(
			`delete from users where id = $1`,
			userId,
		)
	} else {
		_, err = r.db.Exec(
			`delete from users where id = $1`,
			userId,
		)
	}
	if err != nil {
		fmt.Println("Error deleting user", err)
	}

	return err
}

func (r *Repository) DeleteUserProfile(
	ctx context.Context,
	userId int,
	profileId int,
) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	if ok {
		_, err = txn.Exec(
			`delete from user_profiles where user_id = $1 and id = $2`,
			userId,
			profileId,
		)
	} else {
		_, err = r.db.Exec(
			`delete from user_profiles where user_id = $1 and id = $2`,
			userId,
			profileId,
		)
	}
	if err != nil {
		fmt.Println("Error deleting profile info", err)
	}

	return err
}

func (r *Repository) StoreLibraryItems(
	ctx context.Context,
	userId int,
	profileId int,
	items []models.ProfileLibraryItem,
) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	itemsB, err := json.Marshal(items)
	if err != nil {
		fmt.Println("Error unmarshalling library items", err)
		return err
	}
	if ok {
		_, err = txn.Exec(
			`update user_profiles set library_items = $1 where user_id = $2 and id = $3`,
			itemsB,
			userId,
			profileId,
		)
	} else {

		_, err = r.db.Exec(
			`update user_profiles set library_items = $1 where user_id = $2 and id = $3`,
			itemsB,
			userId,
			profileId,
		)
	}
	if err != nil {
		fmt.Println("Error storing library items", err)
	}

	return err
}

func (r *Repository) UpdateServiceAndPreset(
	ctx context.Context,
	userId int,
	profileId int,
	services map[string]string,
	presets []string,
) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	servicesJson, err := json.Marshal(services)
	if err != nil {
		fmt.Println("Error marshalling services map")
		return err
	}
	if ok {
		_, err = txn.Exec(
			`update user_profiles set services = $1, presets = $2  where user_id = $3 and id = $4`,
			servicesJson,
			pq.Array(presets),
			userId,
			profileId,
		)
	} else {
		_, err = r.db.Exec(
			`update user_profiles set services = $1, presets = $2  where user_id = $3 and id = $4`,
			servicesJson,
			pq.Array(presets),
			userId,
			profileId,
		)
	}
	if err != nil {
		fmt.Println("Error updating service and preset", err)
	}

	return err
}
