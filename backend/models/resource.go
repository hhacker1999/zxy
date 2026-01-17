package models

type PaginatedResponse struct {
	Pages        int
	TotalPages   int
	TotalResults int
	Result       any
}

type CreatedBy struct {
	ID           int64  `json:"id"`
	CreditID     string `json:"credit_id"`
	Name         string `json:"name"`
	OriginalName string `json:"original_name"`
	Gender       int64  `json:"gender"`
	ProfilePath  string `json:"profile_path"`
}

type Credits struct {
	Cast []Cast `json:"cast"`
	Crew []Cast `json:"crew"`
}

type Cast struct {
	Adult              bool    `json:"adult"`
	Gender             int64   `json:"gender"`
	ID                 int64   `json:"id"`
	KnownForDepartment string  `json:"known_for_department"`
	Name               string  `json:"name"`
	OriginalName       string  `json:"original_name"`
	Popularity         float64 `json:"popularity"`
	ProfilePath        *string `json:"profile_path"`
	Character          *string `json:"character,omitempty"`
	CreditID           string  `json:"credit_id"`
	Order              *int64  `json:"order,omitempty"`
	Department         *string `json:"department,omitempty"`
	Job                *string `json:"job,omitempty"`
}

type ExternalIDS struct {
	ImdbID      string `json:"imdb_id"`
	FreebaseMid string `json:"freebase_mid"`
	FreebaseID  string `json:"freebase_id"`
	TvdbID      int64  `json:"tvdb_id"`
	TvrageID    int64  `json:"tvrage_id"`
	WikidataID  string `json:"wikidata_id"`
	FacebookID  string `json:"facebook_id"`
	InstagramID string `json:"instagram_id"`
	TwitterID   string `json:"twitter_id"`
}

type Episode struct {
	ID             int64   `json:"id"`
	Name           string  `json:"name"`
	Overview       string  `json:"overview"`
	VoteAverage    float64 `json:"vote_average"`
	VoteCount      float64 `json:"vote_count"`
	AirDate        string  `json:"air_date"`
	EpisodeNumber  int64   `json:"episode_number"`
	EpisodeType    string  `json:"episode_type"`
	ProductionCode string  `json:"production_code"`
	Runtime        int64   `json:"runtime"`
	SeasonNumber   int64   `json:"season_number"`
	ShowID         int64   `json:"show_id"`
	StillPath      string  `json:"still_path"`
}

type Network struct {
	ID            int64  `json:"id"`
	LogoPath      string `json:"logo_path"`
	Name          string `json:"name"`
	OriginCountry string `json:"origin_country"`
}

type ProductionCountry struct {
	ISO3166_1 string `json:"iso_3166_1"`
	Name      string `json:"name"`
}

type SpokenLanguage struct {
	EnglishName string `json:"english_name"`
	ISO639_1    string `json:"iso_639_1"`
	Name        string `json:"name"`
}

type TMDBShow struct {
	Adult               bool                `json:"adult"`
	BackdropPath        string              `json:"backdrop_path"`
	CreatedBy           []CreatedBy         `json:"created_by"`
	EpisodeRunTime      []int64             `json:"episode_run_time"`
	FirstAirDate        string              `json:"first_air_date"`
	Genres              []Genre             `json:"genres"`
	Homepage            string              `json:"homepage"`
	ID                  int64               `json:"id"`
	InProduction        bool                `json:"in_production"`
	Languages           []string            `json:"languages"`
	LastAirDate         string              `json:"last_air_date"`
	LastEpisodeToAir    Episode             `json:"last_episode_to_air"`
	Name                string              `json:"name"`
	NextEpisodeToAir    Episode             `json:"next_episode_to_air"`
	Networks            []Network           `json:"networks"`
	NumberOfEpisodes    int64               `json:"number_of_episodes"`
	NumberOfSeasons     int64               `json:"number_of_seasons"`
	OriginCountry       []string            `json:"origin_country"`
	OriginalLanguage    string              `json:"original_language"`
	OriginalName        string              `json:"original_name"`
	Overview            string              `json:"overview"`
	Popularity          float64             `json:"popularity"`
	PosterPath          string              `json:"poster_path"`
	ProductionCompanies []Network           `json:"production_companies"`
	ProductionCountries []ProductionCountry `json:"production_countries"`
	SpokenLanguages     []SpokenLanguage    `json:"spoken_languages"`
	Status              string              `json:"status"`
	Tagline             string              `json:"tagline"`
	Type                string              `json:"type"`
	VoteAverage         float64             `json:"vote_average"`
	VoteCount           int64               `json:"vote_count"`
	Seasons             []Season            `json:"seasons"`
	ExternalIDS         ExternalIDS         `json:"external_ids"`
	Credits             Credits             `json:"credits"`
	Images              Images              `json:"images"`
	Similar             SimilarShow         `json:"similar"`
}

type GuestStar struct {
	Character          string  `json:"character"`
	CreditID           string  `json:"credit_id"`
	Order              int64   `json:"order"`
	Adult              bool    `json:"adult"`
	Gender             int64   `json:"gender"`
	ID                 int64   `json:"id"`
	KnownForDepartment string  `json:"known_for_department"`
	Name               string  `json:"name"`
	OriginalName       string  `json:"original_name"`
	Popularity         float64 `json:"popularity"`
	ProfilePath        *string `json:"profile_path"`
}

type Season struct {
	ID           string    `json:"_id"`
	AirDate      string    `json:"air_date"`
	Episodes     []Episode `json:"episodes"`
	Name         string    `json:"name"`
	Networks     []Network `json:"networks"`
	Overview     string    `json:"overview"`
	PosterPath   string    `json:"poster_path"`
	SeasonNumber int64     `json:"season_number"`
	VoteAverage  float64   `json:"vote_average"`
}

type TMDBMovie struct {
	ExternalIDS         ExternalIDS         `json:"external_ids"`
	Adult               bool                `json:"adult"`
	Credits             Credits             `json:"credits"`
	BackdropPath        string              `json:"backdrop_path"`
	BelongsToCollection BelongsToCollection `json:"belongs_to_collection"`
	Collection          Collection          `json:"collection"`
	Budget              int64               `json:"budget"`
	Genres              []Genre             `json:"genres"`
	Homepage            string              `json:"homepage"`
	ID                  int64               `json:"id"`
	ImdbID              string              `json:"imdb_id"`
	OriginCountry       []string            `json:"origin_country"`
	OriginalLanguage    string              `json:"original_language"`
	OriginalTitle       string              `json:"original_title"`
	Overview            string              `json:"overview"`
	Popularity          float64             `json:"popularity"`
	PosterPath          string              `json:"poster_path"`
	ProductionCompanies []ProductionCompany `json:"production_companies"`
	ProductionCountries []ProductionCountry `json:"production_countries"`
	ReleaseDate         string              `json:"release_date"`
	Revenue             int64               `json:"revenue"`
	Runtime             int64               `json:"runtime"`
	SpokenLanguages     []SpokenLanguage    `json:"spoken_languages"`
	Status              string              `json:"status"`
	Tagline             string              `json:"tagline"`
	Title               string              `json:"title"`
	Video               bool                `json:"video"`
	VoteAverage         float64             `json:"vote_average"`
	VoteCount           int64               `json:"vote_count"`
	Images              Images              `json:"images"`
	Similar             SimilarMovie        `json:"similar"`
}

type BelongsToCollection struct {
	ID           int64  `json:"id"`
	Name         string `json:"name"`
	PosterPath   string `json:"poster_path"`
	BackdropPath string `json:"backdrop_path"`
}

type Images struct {
	Backdrops []Backdrop `json:"backdrops"`
	Logos     []Backdrop `json:"logos"`
	Posters   []Backdrop `json:"posters"`
}

type Backdrop struct {
	AspectRatio float64 `json:"aspect_ratio"`
	Height      int64   `json:"height"`
	ISO3166_1   string  `json:"iso_3166_1"`
	ISO639_1    string  `json:"iso_639_1"`
	FilePath    string  `json:"file_path"`
	VoteAverage float64 `json:"vote_average"`
	VoteCount   int64   `json:"vote_count"`
	Width       int64   `json:"width"`
}

type ProductionCompany struct {
	ID            int64  `json:"id"`
	LogoPath      string `json:"logo_path"`
	Name          string `json:"name"`
	OriginCountry string `json:"origin_country"`
}

type SimilarMovie struct {
	Page         int64                `json:"page"`
	Results      []SimilarResultMovie `json:"results"`
	TotalPages   int64                `json:"total_pages"`
	TotalResults int64                `json:"total_results"`
}

type SimilarShow struct {
	Page         int64               `json:"page"`
	Results      []SimilarResultShow `json:"results"`
	TotalPages   int64               `json:"total_pages"`
	TotalResults int64               `json:"total_results"`
}

type SimilarResultMovie struct {
	Adult            bool    `json:"adult"`
	BackdropPath     string  `json:"backdrop_path"`
	GenreIDS         []int64 `json:"genre_ids"`
	ID               int64   `json:"id"`
	OriginalLanguage string  `json:"original_language"`
	OriginalTitle    string  `json:"original_title"`
	Overview         string  `json:"overview"`
	Popularity       float64 `json:"popularity"`
	PosterPath       string  `json:"poster_path"`
	ReleaseDate      string  `json:"release_date"`
	Title            string  `json:"title"`
	Video            bool    `json:"video"`
	VoteAverage      float64 `json:"vote_average"`
	VoteCount        int64   `json:"vote_count"`
}

type SimilarResultShow struct {
	Adult            bool     `json:"adult"`
	BackdropPath     string   `json:"backdrop_path"`
	GenreIDS         []int64  `json:"genre_ids"`
	ID               int64    `json:"id"`
	OriginCountry    []string `json:"origin_country"`
	OriginalLanguage string   `json:"original_language"`
	OriginalName     string   `json:"original_name"`
	Overview         string   `json:"overview"`
	Popularity       float64  `json:"popularity"`
	PosterPath       string   `json:"poster_path"`
	FirstAirDate     string   `json:"first_air_date"`
	Name             string   `json:"name"`
	VoteAverage      float64  `json:"vote_average"`
	VoteCount        int64    `json:"vote_count"`
}

type Collection struct {
	ID               int64  `json:"id"`
	Name             string `json:"name"`
	OriginalLanguage string `json:"original_language"`
	OriginalName     string `json:"original_name"`
	Overview         string `json:"overview"`
	PosterPath       string `json:"poster_path"`
	BackdropPath     string `json:"backdrop_path"`
	Parts            []Part `json:"parts"`
}

type Part struct {
	Adult            bool    `json:"adult"`
	BackdropPath     string  `json:"backdrop_path"`
	ID               int64   `json:"id"`
	Name             string  `json:"name"`
	OriginalName     string  `json:"original_name"`
	Overview         string  `json:"overview"`
	PosterPath       string  `json:"poster_path"`
	MediaType        string  `json:"media_type"`
	OriginalLanguage string  `json:"original_language"`
	GenreIDS         []int64 `json:"genre_ids"`
	Popularity       float64 `json:"popularity"`
	ReleaseDate      string  `json:"release_date"`
	Video            bool    `json:"video"`
	VoteAverage      float64 `json:"vote_average"`
	VoteCount        int64   `json:"vote_count"`
}
