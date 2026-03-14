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
	Id             int                  `json:"id"`
	UserIdStr      string               `json:"user_id_str,omitempty"`
	UserId         int                  `json:"user_id,omitempty"`
	Name           string               `json:"name,omitempty"`
	CreatedAt      time.Time            `json:"created_at"`
	UpdatedAt      time.Time            `json:"updated_at"`
	PinHash        string               `json:"pin_hash,omitempty"`
	IsPinProtected bool                 `json:"is_pin_protected"`
	DebridType     string               `json:"debrid_type"`
	DebridKey      string               `json:"-"`
	TraktExpiry    *time.Time           `json:"trakt_expiry"`
	TraktValid     bool                 `json:"trakt_valid"`
	IsAdmin        bool                 `json:"is_admin"`
	LibraryItems   []ProfileLibraryItem `json:"library_items"`
	Webstreamr     bool                 `json:"webstreamr"`
	Torbox         string               `json:"torbox"`
	RealDebrid     string               `json:"real_debrid"`
}

type ProfileTraktDetails struct {
	UserId       int
	ProfileId    int
	Token        string
	RefreshToken string
	Expiry       time.Time
	IsTraktValid bool
}
