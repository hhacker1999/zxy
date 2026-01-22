package models

import "time"

type User struct {
	Id        int           `json:"-"`
	UserId    string        `json:"user_id"`
	Name      string        `json:"name"`
	Email     string        `json:"email"`
	CreatedAt time.Time     `json:"created_at"`
	UpdatedAt time.Time     `json:"updated_at"`
	PwdHash   string        `json:"-"`
	Profiles  []UserProfile `json:"profiles"`
}

type UserProfile struct {
	Id             int       `json:"id"`
	UserIdStr      string    `json:"user_id_str,omitempty"`
	UserId         int       `json:"user_id,omitempty"`
	Name           string    `json:"name,omitempty"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
	PinHash        string    `json:"-"`
	IsPinProtected bool      `json:"is_pin_protected,omitempty"`
	DebridType     string    `json:"debrid_type"`
	DebridKey      string    `json:"-"`
}
