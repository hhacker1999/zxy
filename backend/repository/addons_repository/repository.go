package addonsrepository

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

func (r *Repository) AddAddon(ctx context.Context, addon models.Addon) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	if ok {
		_, err = txn.Exec(
			`insert into profile_addons (manifest_url, enabled, profile_id) values($1, $2, $3)`,
			addon.ManifestUrl,
			addon.Enabled,
			addon.ProfileId,
		)
	} else {
		_, err = r.db.Exec(
			`insert into profile_addons (manifest_url, enabled, profile_id) values($1, $2, $3)`,
			addon.ManifestUrl,
			addon.Enabled,
			addon.ProfileId,
		)
	}
	if err != nil {
		fmt.Println("Error inserting addon to profile", err)

	}

	return err
}

func (r *Repository) UpdateAddon(ctx context.Context, addon models.Addon) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	query := `update profile_addons set enabled = $1 where id =$2`
	var err error
	if ok {
		_, err = txn.Exec(
			query,
			addon.Enabled,
			addon.Id,
		)
	} else {
		_, err = r.db.Exec(
			query,
			addon.Enabled,
			addon.Id,
		)
	}
	if err != nil {
		fmt.Println("Error updating addon", err)

	}

	return err
}

func (r *Repository) RemoveProfileAddons(ctx context.Context, profileId int) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	if ok {
		_, err = txn.Exec(
			`delete from profile_addons where profile_id = $1`,
			profileId,
		)
	} else {
		_, err = r.db.Exec(
			`delete from profile_addons where profile_id = $1`,
			profileId,
		)
	}
	if err != nil {
		fmt.Println("Error removing addons from profile", err)

	}

	return err
}

func (r *Repository) RemoveProfileAddon(ctx context.Context, addonId int) error {
	txn, ok := ctx.Value("txn").(*sql.Tx)
	var err error
	if ok {
		_, err = txn.Exec(
			`delete from profile_addons where id = $1`,
			addonId,
		)
	} else {
		_, err = r.db.Exec(
			`delete from profile_addons where id = $1`,
			addonId,
		)
	}
	if err != nil {
		fmt.Println("Error removing addon from profile", err)
	}

	return err
}

func (r *Repository) GetProfileAddons(profileId int) ([]models.Addon, error) {
	var res []models.Addon
	rows, err := r.db.Query(
		`select id, manifest_url, enabled from profile_addons where profile_id = $1`,
		profileId,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return res, nil
		}

		fmt.Println("Error getting profile addons", err)
		return res, err
	}

	defer rows.Close()

	for rows.Next() {
		var temp models.Addon
		err = rows.Scan(&temp.Id, &temp.ManifestUrl, &temp.Enabled)
		if err != nil {
			fmt.Println("Error scanning get profile addons", err)
			return res, err
		}
		res = append(res, temp)
	}

	return res, nil
}
