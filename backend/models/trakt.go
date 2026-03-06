package models

import "time"

type TraktAuthRes struct {
	AccessToken  string `json:"access_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int64  `json:"expires_in"`
	RefreshToken string `json:"refresh_token"`
	Scope        string `json:"scope"`
	CreatedAt    int64  `json:"created_at"`
	Expiry       time.Time
}

type TraktPlaybackHistoryItem struct {
	Plays         int64         `json:"plays"`
	LastWatchedAt time.Time     `json:"last_watched_at"`
	LastUpdatedAt time.Time     `json:"last_updated_at"`
	ResetAt       *time.Time    `json:"reset_at"`
	Show          Item          `json:"show"`
	Movie         Item          `json:"movie"`
	Seasons       []TraktSeason `json:"seasons"`
}

type TraktSeason struct {
	Number   int64          `json:"number"`
	Episodes []TraktEpisode `json:"episodes"`
}

type TraktEpisode struct {
	Number        int64     `json:"number"`
	Plays         int64     `json:"plays"`
	LastWatchedAt time.Time `json:"last_watched_at"`
}

type Item struct {
	Title string `json:"title"`
	Year  int64  `json:"year"`
	IDS   IDS    `json:"ids"`
}

type TraktTrendingResponeElement struct {
	Movie TraktItem `json:"movie"`
	Show  TraktItem `json:"show"`
}

type TraktItem struct {
	Title                 string    `json:"title"`
	Year                  int64     `json:"year"`
	IDS                   IDS       `json:"ids"`
	Tagline               string    `json:"tagline"`
	Overview              string    `json:"overview"`
	Runtime               int64     `json:"runtime"`
	Country               string    `json:"country"`
	Trailer               string    `json:"trailer"`
	Homepage              string    `json:"homepage"`
	Status                string    `json:"status"`
	Rating                float64   `json:"rating"`
	Votes                 int64     `json:"votes"`
	CommentCount          int64     `json:"comment_count"`
	UpdatedAt             time.Time `json:"updated_at"`
	Language              string    `json:"language"`
	Languages             []string  `json:"languages"`
	AvailableTranslations []string  `json:"available_translations"`
	Genres                []string  `json:"genres"`
	Subgenres             []string  `json:"subgenres"`
	OriginalTitle         string    `json:"original_title"`
	Images                Images    `json:"images"`
	Colors                Colors    `json:"colors"`
	Released              string    `json:"released"`
	AfterCredits          bool      `json:"after_credits"`
	DuringCredits         bool      `json:"during_credits"`
	Certification         string    `json:"certification"`
}

type Colors struct {
	Poster []string `json:"poster"`
}

type IDS struct {
	Trakt int64  `json:"trakt"`
	Slug  string `json:"slug"`
	Imdb  string `json:"imdb"`
	Tmdb  int64  `json:"tmdb"`
	Plex  Plex   `json:"plex"`
}

type Plex struct {
	GUID string `json:"guid"`
	Slug string `json:"slug"`
}

type TraktPlaybackResponeElement struct {
	Progress float64      `json:"progress"`
	PausedAt time.Time    `json:"paused_at"`
	ID       int64        `json:"id"`
	Type     string       `json:"type"`
	Movie    MovieClass   `json:"movie"`
	Episode  EpisodeClass `json:"episode"`
	Show     Show         `json:"show"`
}

type EpisodeClass struct {
	Season int64      `json:"season"`
	Number int64      `json:"number"`
	Title  string     `json:"title"`
	IDS    EpisodeIDS `json:"ids"`
}

type EpisodeIDS struct {
	Trakt int64   `json:"trakt"`
	Tvdb  *int64  `json:"tvdb"`
	Imdb  string  `json:"imdb"`
	Tmdb  int64   `json:"tmdb"`
	Slug  *string `json:"slug,omitempty"`
}

type MovieClass struct {
	Title string   `json:"title"`
	Year  int64    `json:"year"`
	IDS   MovieIDS `json:"ids"`
}

type MovieIDS struct {
	Trakt int64  `json:"trakt"`
	Slug  string `json:"slug"`
	Imdb  string `json:"imdb"`
	Tmdb  int64  `json:"tmdb"`
}

type Show struct {
	Title string     `json:"title"`
	Year  int64      `json:"year"`
	IDS   EpisodeIDS `json:"ids"`
}
