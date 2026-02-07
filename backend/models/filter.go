package models

type ProfileLibraryItem struct {
	Name   string        `json:"name"`
	Filter LibraryFilter `json:"filter"`
}

type LibraryFilter struct {
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
	Items          int     `json:"items"`
	IncludedGenres []int   `json:"included_genres"`
	ExcludedGenres []int   `json:"excluded_genres"`
	Page           int     `json:"page"`
}

var DefaultLibraryItems = []ProfileLibraryItem{

	{
		Name: "Trending Shows",
		Filter: LibraryFilter{
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
