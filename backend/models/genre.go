package models

type TMDBGenreResponse struct {
	Genres []Genre `json:"genres"`
}

type ZxyGenreResponse struct {
	MovieGenre []Genre `json:"movie_genre"`
	ShowGenre  []Genre `json:"show_genre"`
}

type Genre struct {
	Id   int    `json:"id"`
	Name string `json:"name"`
}
