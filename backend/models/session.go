package models

import "time"

type Session struct {
	Id     int
	UserId int
	Expiry time.Time
	Token  string
}

type ProfileSession struct {
	Id           int
	ProfileId    int
	SessionId    int
	Token        string
	Expiry       time.Time
	RefreshToken string
}
