package models

import "time"

type TraktAuthRes struct {
	AccessToken  string `json:"access_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int64  `json:"expires_in"`
	RefreshToken string `json:"refresh_token"`
	Scope        string `json:"scope"`
	CreatedAt    int64  `json:"created_at"`
}

type TraktPlaybackHistoryItem struct {
	Plays         int64      `json:"plays"`
	LastWatchedAt time.Time  `json:"last_watched_at"`
	LastUpdatedAt time.Time  `json:"last_updated_at"`
	ResetAt       *time.Time `json:"reset_at"`
	Show          Item       `json:"show"`
	Movie         Item       `json:"movie"`
	Seasons       []Season   `json:"seasons"`
}

type Season struct {
	Number   int64     `json:"number"`
	Episodes []Episode `json:"episodes"`
}

type Episode struct {
	Number        int64     `json:"number"`
	Plays         int64     `json:"plays"`
	LastWatchedAt time.Time `json:"last_watched_at"`
}

type Item struct {
	Title string `json:"title"`
	Year  int64  `json:"year"`
	IDS   IDS    `json:"ids"`
}

type IDS struct {
	Trakt int64  `json:"trakt"`
	Slug  string `json:"slug"`
	Tvdb  int64  `json:"tvdb"`
	Imdb  string `json:"imdb"`
	Tmdb  int64  `json:"tmdb"`
}
