package models

const INTERNAL = "internal"
const TRAKT = "trakt"
const TRAKT_PRIVATE = "trakt_private"

const TRENDING = "trending"

type ProfileLibraryItem struct {
	Name   string        `json:"name"`
	Filter LibraryFilter `json:"filter"`
}

type LibraryFilter struct {
	Type           string  `json:"type"`
	Items          int     `json:"items"`
	TraktId        string  `json:"trakt_url"`
	IsTrending     bool    `json:"is_trending"`
	IsMovie        bool    `json:"is_movie"`
	ThisWeek       bool    `json:"this_week"`
	ThisMonth      bool    `json:"this_month"`
	Years          []int   `json:"years"`
	IsFirstAir     bool    `json:"is_first_air"`
	ImdbRating     float64 `json:"imdb_rating"`
	Language       string  `json:"language"`
	Sort           string  `json:"sort"`
	IsAsc          bool    `json:"is_asc"`
	IncludedGenres []int   `json:"included_genres"`
	ExcludedGenres []int   `json:"excluded_genres"`
	Page           int     `json:"page"`
	MinVotes       int     `json:"min_votes"`
}

var DefaultLibraryItems = []ProfileLibraryItem{

	{
		Name: "Trending Shows",
		Filter: LibraryFilter{
			Type:           TRAKT,
			TraktId:        TRENDING,
			IsTrending:     true,
			IsMovie:        false,
			ThisWeek:       false,
			ThisMonth:      false,
			Years:          []int{},
			IsFirstAir:     false,
			ImdbRating:     0,
			Language:       "",
			Sort:           "",
			IsAsc:          false,
			Items:          20,
			IncludedGenres: []int{},
			ExcludedGenres: []int{},
			Page:           1,
		},
	},
	{
		Name: "Trending Movies",
		Filter: LibraryFilter{
			Type:           TRAKT,
			TraktId:        TRENDING,
			IsTrending:     true,
			IsMovie:        true,
			ThisWeek:       false,
			ThisMonth:      false,
			Years:          []int{},
			IsFirstAir:     false,
			ImdbRating:     0,
			Language:       "",
			Sort:           "",
			IsAsc:          false,
			Items:          20,
			IncludedGenres: []int{},
			ExcludedGenres: []int{},
			Page:           1,
		},
	},
	{
		Name: "Popular Movies",
		Filter: LibraryFilter{
			Type:           INTERNAL,
			IsTrending:     false,
			IsMovie:        true,
			ThisWeek:       false,
			ThisMonth:      false,
			Years:          []int{},
			IsFirstAir:     false,
			ImdbRating:     0,
			Language:       "",
			Sort:           "popularity",
			IsAsc:          false,
			Items:          20,
			IncludedGenres: []int{},
			ExcludedGenres: []int{},
			Page:           1,
		},
	},
	{
		Name: "Popular Shows",
		Filter: LibraryFilter{
			Type:           INTERNAL,
			IsTrending:     false,
			IsMovie:        false,
			ThisWeek:       false,
			ThisMonth:      false,
			Years:          []int{},
			IsFirstAir:     false,
			ImdbRating:     0,
			Language:       "",
			Sort:           "popularity",
			IsAsc:          false,
			Items:          20,
			IncludedGenres: []int{},
			ExcludedGenres: []int{},
			Page:           1,
		},
	},
}
