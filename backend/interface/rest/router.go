package rest

import (
	"context"
	"database/sql"
	"net/http"
	"zxy/models"
	sessionrepository "zxy/repository/session_repository"
	userrepository "zxy/repository/user_repository"
	addonusecase "zxy/usecase/addon_usecase"
	tmdbusecase "zxy/usecase/tmdb_usecase"
	userusecase "zxy/usecase/user_usecase"

	"github.com/go-chi/chi/v5"
)

type RestInterface struct {
	addonuc     *addonusecase.Usecase
	tmdbUc      *tmdbusecase.Usecase
	userUC      *userusecase.Usecase
	userRepo    *userrepository.Repository
	sessionRepo *sessionrepository.Repository
}

func New(
	addonuc *addonusecase.Usecase,
	tmdbUc *tmdbusecase.Usecase,
	userUC *userusecase.Usecase,
	userRepo *userrepository.Repository,
	sessionRepo *sessionrepository.Repository,
) *RestInterface {
	return &RestInterface{
		addonuc:     addonuc,
		tmdbUc:      tmdbUc,
		userUC:      userUC,
		userRepo:    userRepo,
		sessionRepo: sessionRepo,
	}
}

func (i *RestInterface) SetupRoutes() *chi.Mux {
	router := chi.NewRouter()
	router.Post("/signup", i.handleSignup)
	router.Post("/login", i.handleLogin)
	router.Post("/profile/login", i.SessionHandler(i.handleProfileLogin, false))
	router.Get("/user", i.SessionHandler(i.handleGetUser, false))
	router.Get("/streams", i.HandleGetStream)
	router.Get("/discover/movies", i.HandleDiscoverMovies)
	router.Get("/discover/shows", i.HandleDiscoverShows)
	router.Get("/trending/movies", i.HandleGetTrendingMovies)
	router.Get("/trending/shows", i.HandleGetTrendingShows)
	router.Get("/search/show", i.HandleSearchShows)
	router.Get("/search/movie", i.HandleSearchMovies)
	router.Get("/movie/{id}", i.HandleGetMovieInfo)
	router.Get("/show/{id}", i.HandleGetShowInfo)
	router.Get("/genre", i.HandleGetGenre)
	router.Get("/configuration", i.HandleGetConfiguration)
	return router
}

func (i *RestInterface) SessionHandler(next http.HandlerFunc, isProfile bool) http.HandlerFunc {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		cookieName := "session_token"
		if isProfile {
			cookieName = "profile_token"
		}
		cookie, err := r.Cookie(cookieName)
		if err != nil || len(cookie.Value) == 0 {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		token := cookie.Value

		var session models.Session
		var profileId int
		if isProfile {
			profileSession, err := i.sessionRepo.GetProfileSession(token)
			if err != nil {
				if err == sql.ErrNoRows {
					w.WriteHeader(http.StatusUnauthorized)
					return
				}
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			profileId = profileSession.ProfileId
			session, err = i.sessionRepo.GetUserSessionFromId(profileSession.SessionId)
			if err != nil {
				if err == sql.ErrNoRows {
					w.WriteHeader(http.StatusUnauthorized)
					return
				}
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
		} else {
			session, err = i.sessionRepo.GetUserSession(token)
			if err != nil {
				if err == sql.ErrNoRows {
					w.WriteHeader(http.StatusUnauthorized)
					return
				}
				w.WriteHeader(http.StatusInternalServerError)
				return
			}

		}

		newR := r.WithContext(context.WithValue(r.Context(), "user_id", session.UserId))
		newR = newR.WithContext(context.WithValue(newR.Context(), "session_id", session.Id))
		if isProfile {
			newR = newR.WithContext(
				context.WithValue(newR.Context(), "profile_id", profileId),
			)
		}

		next.ServeHTTP(w, newR)
	})
}
