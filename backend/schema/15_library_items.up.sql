update user_profiles set library_items = '[
  {
    "name": "Trending Shows",
    "filter": {
      "type" : "trakt",
      "trakt_url": "trending",
      "is_trending": true,
      "is_movie": false,
      "this_week": false,
      "this_month": false,
      "years": [],
      "is_first_air": false,
      "imdb_rating": 0,
      "language": "",
      "sort": "",
      "is_asc": false,
      "items": 20,
      "included_genres": [],
      "excluded_genres": [],
      "page": 1,
      "min_votes": 0
    }
  },
  {
    "name": "Trending Movies",
    "filter": {
      "type" : "trakt",
      "trakt_url": "trending",
      "is_trending": true,
      "is_movie": true,
      "this_week": false,
      "this_month": false,
      "years": [],
      "is_first_air": false,
      "imdb_rating": 0,
      "language": "",
      "sort": "",
      "is_asc": false,
      "items": 20,
      "included_genres": [],
      "excluded_genres": [],
      "page": 1,
      "min_votes": 0
    }
  },
  {
    "name": "Popular Movies",
    "filter": {
      "type" : "internal",
      "trakt_url": "trending",
      "is_trending": false,
      "is_movie": true,
      "this_week": false,
      "this_month": false,
      "years": [],
      "is_first_air": false,
      "imdb_rating": 0,
      "language": "",
      "sort": "popularity",
      "is_asc": false,
      "items": 20,
      "included_genres": [],
      "excluded_genres": [],
      "page": 1,
      "min_votes": 0
    }
  },
  {
    "name": "Popular Shows",
    "filter": {
      "type" : "internal",
      "trakt_url": "trending",
      "is_trending": false,
      "is_movie": false,
      "this_week": false,
      "this_month": false,
      "years": [],
      "is_first_air": false,
      "imdb_rating": 0,
      "language": "",
      "sort": "popularity",
      "is_asc": false,
      "items": 20,
      "included_genres": [],
      "excluded_genres": [],
      "page": 1,
      "min_votes": 0
    }
  }
]'::jsonb;
