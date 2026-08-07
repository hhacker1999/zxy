package rest

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"
	"sync"
	"time"
	zxyWs "zxy/interface/websocket"
	"zxy/models"
	sessionrepository "zxy/repository/session_repository"
	userrepository "zxy/repository/user_repository"
	addonusecase "zxy/usecase/addon_usecase"
	progressusecase "zxy/usecase/progress_usecase"
	tmdbusecase "zxy/usecase/tmdb_usecase"
	traktusecase "zxy/usecase/trakt_usecase"
	userusecase "zxy/usecase/user_usecase"

	"github.com/go-chi/chi/v5"
	"github.com/redis/go-redis/v9"
)

type RedirectError struct {
	URL        string
	StatusCode int
	Message    string
}

func (e *RedirectError) Error() string {
	return fmt.Sprintf("%s: %s", e.Message, e.URL)
}

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
	addonuc       *addonusecase.Usecase
	tmdbUc        *tmdbusecase.Usecase
	userUC        *userusecase.Usecase
	userRepo      *userrepository.Repository
	sessionRepo   *sessionrepository.Repository
	progressUC    *progressusecase.Usecase
	traktUC       *traktusecase.Usecase
	encrKey       string
	proxy         *httputil.ReverseProxy
	client        *http.Client
	urlMap        map[string]RedirectUrlInfo
	mtx           *sync.RWMutex
	cronCancel    context.CancelFunc
	sockerHandler *zxyWs.WSHandler
	ytRedisDb     *redis.Client
	ytProxy       string
}

func New(
	addonuc *addonusecase.Usecase,
	tmdbUc *tmdbusecase.Usecase,
	userUC *userusecase.Usecase,
	userRepo *userrepository.Repository,
	sessionRepo *sessionrepository.Repository,
	progressUC *progressusecase.Usecase,
	encrKey string,
	sockerHandler *zxyWs.WSHandler,
	traktUC *traktusecase.Usecase,
	ytRedisDb *redis.Client,
	ytProxy string,
) *RestInterface {
	client := &http.Client{
		Timeout: 5 * time.Second,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			fmt.Println("We are inside redirect")
			splittedHost := strings.Split(req.URL.Host, ":")
			fmt.Println(req.URL.String())
			if len(splittedHost) == 1 {
				fmt.Println("Found non internal host")
				return &RedirectError{
					URL:        req.URL.String(),
					StatusCode: 200, // You can define your own logic here
					Message:    "Found final url",
				}
			}
			return nil
		},
	}
	return &RestInterface{
		addonuc:       addonuc,
		tmdbUc:        tmdbUc,
		userUC:        userUC,
		userRepo:      userRepo,
		sessionRepo:   sessionRepo,
		progressUC:    progressUC,
		encrKey:       encrKey,
		client:        client,
		urlMap:        map[string]RedirectUrlInfo{},
		mtx:           &sync.RWMutex{},
		sockerHandler: sockerHandler,
		traktUC:       traktUC,
		ytRedisDb:     ytRedisDb,
		ytProxy:       ytProxy,
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

	// Auth
	router.Post("/signup", i.handleSignup)
	router.Post("/login", i.handleLogin)
	router.Post("/profile/login", i.SessionHandler(i.handleProfileLogin, false))

	// User
	router.Get("/user", i.SessionHandler(i.handleGetUser, false))
	router.Delete("/user", i.SessionHandler(i.handleDeleteUser, true))

	// Profile
	router.Get("/user/profile", i.SessionHandler(i.handleGetUserProfile, true))
	router.Post("/user/profile", i.SessionHandler(i.handleCreateUserProfile, true))
	router.Put("/user/profile", i.SessionHandler(i.handleUpdateUserProfile, true))
	router.Put("/user/profile/list", i.SessionHandler(i.handleUpdateUserProfileLists, true))
	router.Delete("/user/profile", i.SessionHandler(i.handleDeleteUserProfile, true))

	// Streaming
	router.Get("/stream/*", i.handleStream)
	router.Get("/proxy", i.handleProxy)
	router.Get("/streams", i.SessionHandler(i.HandleGetStream, true))
	router.Get("/v2/streams", i.SessionHandler(i.HandleGetStreamV2, true))
	router.Get("/stream_url", i.SessionHandler(i.handleFinalUrl, true))
	router.Get("/yt_stream", i.SessionHandler(i.handleYtStream, true))

	// WebSocket
	router.Get("/ws", i.SessionHandler(i.sockerHandler.HandleClientConnectionRequest, true))

	// Discover
	router.Get("/discover/movies", i.SessionHandler(i.HandleDiscoverMovies, true))
	router.Get("/discover/shows", i.SessionHandler(i.HandleDiscoverShows, true))
	router.Get("/trending/movies", i.SessionHandler(i.HandleGetTrendingMovies, true))
	router.Get("/trending/shows", i.SessionHandler(i.HandleGetTrendingShows, true))
	router.Get("/search/show", i.SessionHandler(i.HandleSearchShows, true))
	router.Get("/search/movie", i.SessionHandler(i.HandleSearchMovies, true))
	router.Get("/genre", i.HandleGetGenre)
	router.Get("/configuration", i.HandleGetConfiguration)

	// Content
	router.Get("/movie/{id}", i.SessionHandler(i.HandleGetMovieInfo, true))
	router.Get("/show/{id}", i.SessionHandler(i.HandleGetShowInfo, true))

	// Progress
	router.Get("/continue_watching", i.SessionHandler(i.HandleGetContinueWatching, true))
	router.Delete("/continue_watching/{id}", i.SessionHandler(i.handleDeleteContinueWatching, true))
	router.Get("/movie/{id}/progress", i.SessionHandler(i.HandleGetMovieProgress, true))
	router.Get("/show/{id}/progress", i.SessionHandler(i.HandleGetShowProgress, true))
	router.Post("/movie/update_progress", i.SessionHandler(i.HandleMovieProgressUpdate, true))
	router.Post("/show/update_progress", i.SessionHandler(i.HandleShowProgressUpdate, true))
	router.Post("/movie/{id}/watched", i.SessionHandler(i.handleMovieWatched, true))
	router.Post("/show/{id}/watched", i.SessionHandler(i.handleShowWatched, true))

	// Library
	router.Post("/discover/library", i.SessionHandler(i.handleLibrary, true))
	router.Post("/user/library", i.SessionHandler(i.HandleAddToLibrary, true))
	router.Delete("/user/library", i.SessionHandler(i.HandleDeleteFromLibrary, true))
	router.Post("/user/library/check", i.SessionHandler(i.HandleCheckIfInLibrary, true))

	// Trakt
	router.Get("/trakt_url", i.SessionHandler(i.HandleGetTraktUrl, true))
	router.Get("/trakt", i.HandleTraktRedirect)
	router.Delete("/trakt", i.SessionHandler(i.HandleTraktDelete, true))

	// Sources
	router.Post("/user/source", i.SessionHandler(i.HandleAddSource, true))
	router.Delete("/user/source", i.SessionHandler(i.HandleRemoveSource, true))

	// Streamio Addons
	router.Post("/profile/addon", i.SessionHandler(i.HandleAddAddon, true))
	router.Delete("/profile/addon", i.SessionHandler(i.HandleRemoveAddon, true))
	router.Post("/profile/addon/enable", i.SessionHandler(i.HandleEnableAddon, true))
	router.Post("/profile/addon/disable", i.SessionHandler(i.HandleDisableAddon, true))

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
