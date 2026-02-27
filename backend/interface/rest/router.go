package rest

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"sync"
	"time"
	"zxy/models"
	sessionrepository "zxy/repository/session_repository"
	userrepository "zxy/repository/user_repository"
	addonusecase "zxy/usecase/addon_usecase"
	progressusecase "zxy/usecase/progress_usecase"
	tmdbusecase "zxy/usecase/tmdb_usecase"
	userusecase "zxy/usecase/user_usecase"

	"github.com/go-chi/chi/v5"
)

type AnonymizerTransport struct {
	RoundTripper http.RoundTripper
}

func (t *AnonymizerTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	req.Header.Del("X-Forwarded-For")
	req.Header.Del("X-Real-Ip")
	req.Header.Del("Forwarded")
	req.Header.Del("User-Agent")

	return t.RoundTripper.RoundTrip(req)
}

type RedirectUrlInfo struct {
	FinalUrl string
	UrlTime  time.Time
}

type RestInterface struct {
	addonuc     *addonusecase.Usecase
	tmdbUc      *tmdbusecase.Usecase
	userUC      *userusecase.Usecase
	userRepo    *userrepository.Repository
	sessionRepo *sessionrepository.Repository
	progressUC  *progressusecase.Usecase
	encrKey     string
	proxy       *httputil.ReverseProxy
	client      *http.Client
	urlMap      map[string]RedirectUrlInfo
	mtx         *sync.RWMutex
	cronCancel  context.CancelFunc
}

func New(
	addonuc *addonusecase.Usecase,
	tmdbUc *tmdbusecase.Usecase,
	userUC *userusecase.Usecase,
	userRepo *userrepository.Repository,
	sessionRepo *sessionrepository.Repository,
	progressUC *progressusecase.Usecase,
	encrKey string,
) *RestInterface {
	client := &http.Client{
		Timeout: 5 * time.Second,
	}
	return &RestInterface{
		addonuc:     addonuc,
		tmdbUc:      tmdbUc,
		userUC:      userUC,
		userRepo:    userRepo,
		sessionRepo: sessionRepo,
		progressUC:  progressUC,
		encrKey:     encrKey,
		client:      client,
		urlMap:      map[string]RedirectUrlInfo{},
		mtx:         &sync.RWMutex{},
	}
}

func (i *RestInterface) SetupRoutes() *chi.Mux {
	proxy := &httputil.ReverseProxy{
		Director: func(req *http.Request) {
			rawUrl, ok := req.Context().Value("url").(string)
			if !ok {
				fmt.Println("Invalid url")
				return
			}

			target, err := url.Parse(rawUrl)
			if err != nil {
				fmt.Println("Error parsing url", err)
				return
			}

			req.Header.Del("X-Forwarded-For")
			req.Header.Del("X-Real-Ip")
			req.Header.Del("Forwarded")

			req.URL.Scheme = target.Scheme
			req.URL.Host = target.Host
			req.URL.Path = target.Path
			req.Host = target.Host
		},
		Transport: &AnonymizerTransport{RoundTripper: http.DefaultTransport},
	}
	i.proxy = proxy

	ctx, fnc := context.WithCancel(context.Background())
	i.cronCancel = fnc
	go i.urlCleanerCron(ctx)

	router := chi.NewRouter()
	router.Post("/signup", i.handleSignup)
	router.Post("/login", i.handleLogin)
	router.Get("/stream", i.handleStream)
	router.Get("/proxy", i.handleProxy)
	router.Post("/profile/login", i.SessionHandler(i.handleProfileLogin, false))
	router.Get("/user", i.SessionHandler(i.handleGetUser, false))
	router.Get("/user/profile", i.SessionHandler(i.handleGetUserProfile, true))
	router.Post("/user/profile", i.SessionHandler(i.handleCreateUserProfile, true))
	router.Put("/user/profile", i.SessionHandler(i.handleUpdateUserProfile, true))
	router.Put("/user/profile/list", i.SessionHandler(i.handleUpdateUserProfileLists, true))
	router.Delete("/user/profile", i.SessionHandler(i.handleDeleteUserProfile, true))
	router.Delete("/user", i.SessionHandler(i.handleDeleteUser, true))
	router.Get("/streams", i.SessionHandler(i.HandleGetStream, true))
	router.Get("/discover/movies", i.SessionHandler(i.HandleDiscoverMovies, true))
	router.Get("/discover/shows", i.SessionHandler(i.HandleDiscoverShows, true))
	router.Get("/trending/movies", i.SessionHandler(i.HandleGetTrendingMovies, true))
	router.Get("/trending/shows", i.SessionHandler(i.HandleGetTrendingShows, true))
	router.Get("/search/show", i.SessionHandler(i.HandleSearchShows, true))
	router.Get("/search/movie", i.SessionHandler(i.HandleSearchMovies, true))
	router.Get("/movie/{id}", i.SessionHandler(i.HandleGetMovieInfo, true))
	router.Get("/show/{id}", i.SessionHandler(i.HandleGetShowInfo, true))
	router.Get("/genre", i.HandleGetGenre)
	router.Get("/configuration", i.HandleGetConfiguration)
	router.Get("/continue_watching", i.SessionHandler(i.HandleGetContinueWatching, true))
	router.Get("/movie/{id}/progress", i.SessionHandler(i.HandleGetMovieProgress, true))
	router.Get("/show/{id}/progress", i.SessionHandler(i.HandleGetShowProgress, true))
	router.Post("/movie/update_progress", i.SessionHandler(i.HandleMovieProgressUpdate, true))
	router.Post("/show/update_progress", i.SessionHandler(i.HandleShowProgressUpdate, true))
	router.Post("/user/debrid/api", i.SessionHandler(i.HandleAddDebridKey, true))
	router.Delete("/user/debrid/api", i.SessionHandler(i.HandleRemoveDebridKey, true))
	router.Post("/discover/library", i.SessionHandler(i.handleLibrary, true))
	router.Post("/movie/{id}/watched", i.SessionHandler(i.handleMovieWatched, true))
	router.Post("/show/{id}/watched", i.SessionHandler(i.handleShowWatched, true))
	router.Delete("/continue_watching/{id}", i.SessionHandler(i.handleDeleteContinueWatching, true))
	router.Get("/stream_url", i.SessionHandler(i.handleFinalUrl, true))
	return router
}

func (i *RestInterface) urlCleanerCron(ctx context.Context) {
	timer := time.NewTicker(time.Minute * 15)
	defer timer.Stop()

	for {
		select {
		case <-timer.C:
			fmt.Println("Clearing old urls")
			i.mtx.Lock()
			for k, v := range i.urlMap {
				if time.Since(v.UrlTime) > time.Hour {
					fmt.Println("removing old url ", k)
					delete(i.urlMap, k)
				}
			}
			i.mtx.Unlock()
		case <-ctx.Done():
			return
		}
	}

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

func (i *RestInterface) Exit() {
	i.cronCancel()
}
