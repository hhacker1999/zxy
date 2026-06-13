package jellyfin

import (
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"
	sessionrepository "zxy/repository/session_repository"
	addonusecase "zxy/usecase/addon_usecase"
	progressusecase "zxy/usecase/progress_usecase"
	tmdbusecase "zxy/usecase/tmdb_usecase"
	userusecase "zxy/usecase/user_usecase"

	"github.com/go-chi/chi/v5"
)

type Config struct {
	ServerID      string
	PublicURL     string
	ImageBase     string
	ResolveStream func(internal string) (string, error)
	GetRequestIP  func(r *http.Request) string
}

type Server struct {
	serverID      string
	publicURL     string
	imageBase     string
	userUC        *userusecase.Usecase
	sessionRepo   *sessionrepository.Repository
	tmdbUC        *tmdbusecase.Usecase
	addonUC       *addonusecase.Usecase
	progressUC    *progressusecase.Usecase
	auth          *authStore
	items         *itemRegistry
	streamCache   map[string]cachedStream
	streamMu      sync.RWMutex
	resolveStream func(string) (string, error)
	getRequestIP  func(*http.Request) string
}

func New(
	cfg Config,
	userUC *userusecase.Usecase,
	sessionRepo *sessionrepository.Repository,
	tmdbUC *tmdbusecase.Usecase,
	addonUC *addonusecase.Usecase,
	progressUC *progressusecase.Usecase,
) *Server {
	serverID := cfg.ServerID
	if serverID == "" {
		serverID = defaultServerID
	}
	resolveStream := cfg.ResolveStream
	if resolveStream == nil {
		resolveStream = func(string) (string, error) { return "", fmt.Errorf("stream resolver not configured") }
	}
	getRequestIP := cfg.GetRequestIP
	if getRequestIP == nil {
		getRequestIP = func(*http.Request) string { return "" }
	}
	return &Server{
		serverID:      serverID,
		publicURL:     trimSlash(cfg.PublicURL),
		imageBase:     cfg.ImageBase,
		userUC:        userUC,
		sessionRepo:   sessionRepo,
		tmdbUC:        tmdbUC,
		addonUC:       addonUC,
		progressUC:    progressUC,
		auth:          newAuthStore(),
		items:         newItemRegistry(),
		streamCache:   make(map[string]cachedStream),
		resolveStream: resolveStream,
		getRequestIP:  getRequestIP,
	}
}

func trimSlash(v string) string {
	for len(v) > 0 && v[len(v)-1] == '/' {
		v = v[:len(v)-1]
	}
	return v
}

func (s *Server) cacheStream(key string, stream cachedStream) {
	s.streamMu.Lock()
	defer s.streamMu.Unlock()
	stream.ExpiresAt = time.Now().Add(30 * time.Minute)
	s.streamCache[key] = stream
}

func (s *Server) getCachedStream(key string) (cachedStream, bool) {
	s.streamMu.RLock()
	defer s.streamMu.RUnlock()
	stream, ok := s.streamCache[key]
	if !ok || time.Now().After(stream.ExpiresAt) {
		return cachedStream{}, false
	}
	return stream, true
}

func (s *Server) streamURL(itemID, token string) string {
	return fmt.Sprintf("%s/Videos/%s/stream?Static=true&MediaSourceId=%s&ApiKey=%s",
		s.publicURL, itemID, mediaSourceID(itemID), token)
}

func (s *Server) RegisterRoutes(r chi.Router) {
	jfLog("registering routes publicURL=%s serverID=%s", s.publicURL, s.serverID)
	s.mountRoutes(r)
	r.Route("/emby", func(r chi.Router) {
		jfLog("registering emby-prefixed jellyfin routes")
		s.mountRoutes(r)
	})
}

func (s *Server) mountRoutes(r chi.Router) {
	r.NotFound(s.handleNotFound)

	r.Get("/System/Info/Public", s.wrap("System/Info/Public", s.handleSystemInfoPublic))
	r.Get("/System/Info", s.wrap("System/Info", s.handleSystemInfo))
	r.Get("/System/Endpoint", s.wrap("System/Endpoint", s.handleSystemEndpoint))
	r.Get("/System/Ping", s.wrap("System/Ping", s.handleSystemPing))
	r.Get("/System/Configuration", s.wrap("System/Configuration", s.handleSystemConfiguration))
	r.Get("/System/Configuration/public", s.wrap("System/Configuration/public", s.handleSystemConfiguration))
	r.Get("/System/Configuration/encoding", s.wrap("System/Configuration/encoding", s.handleEncodingOptions))
	r.Get("/QuickConnect/Enabled", s.wrap("QuickConnect/Enabled", s.handleQuickConnectEnabled))
	r.Get("/ScheduledTasks", s.wrap("ScheduledTasks", s.handleEmptyArray))
	r.Get("/Plugins", s.wrap("Plugins", s.handleEmptyArray))
	r.Get("/Sessions", s.wrapAuth("Sessions", s.handleEmptyArray))
	r.Get("/Branding/Configuration", s.wrap("Branding/Configuration", s.handleBrandingConfiguration))

	r.Post("/Users/AuthenticateByName", s.wrap("Users/AuthenticateByName", s.handleAuthenticateByName))
	r.Get("/Users/Public", s.wrap("Users/Public", s.handleUsersPublic))
	r.Get("/Users/Me", s.wrapAuth("Users/Me", s.handleUsersMe))
	r.Get("/Users/Me/Views", s.wrapAuth("Users/Me/Views", s.handleUserViews))
	r.Get("/Users/Me/Items", s.wrapAuth("Users/Me/Items", s.handleUserItems))
	r.Get("/Users/Me/Items/Resume", s.wrapAuth("Users/Me/Items/Resume", s.handleResumeItems))
	r.Get("/Users/Me/Items/Latest", s.wrapAuth("Users/Me/Items/Latest", s.handleLatestItems))
	r.Get("/Users/Me/Items/NextUp", s.wrapAuth("Users/Me/Items/NextUp", s.handleNextUpItems))
	r.Get("/Users/{userId}", s.wrapAuth("Users/{userId}", s.handleGetUserByID))

	r.Get("/UserViews", s.wrapAuth("UserViews", s.handleUserViewsQuery))
	r.Get("/UserViews/GroupingOptions", s.wrapAuth("UserViews/GroupingOptions", s.handleEmptyArray))

	r.Get("/Library/MediaFolders", s.wrapAuth("Library/MediaFolders", s.handleMediaFolders))
	r.Get("/Library/VirtualFolders", s.wrapAuth("Library/VirtualFolders", s.handleVirtualFolders))

	r.Get("/Items/Root", s.wrapAuth("Items/Root", s.handleRootFolder))
	r.Get("/Items/Latest", s.wrapAuth("Items/Latest", s.handleItemsLatestQuery))
	r.Get("/Items/", s.wrapAuth("Items/ empty", s.handleItemsEmptyQuery))
	r.Get("/Items", s.wrapAuth("Items", s.handleItemsQuery))
	r.Get("/UserItems/Resume", s.wrapAuth("UserItems/Resume", s.handleUserItemsResumeQuery))
	r.Get("/Users/{userId}/Views", s.wrapAuth("Users/{userId}/Views", s.handleUserViews))
	r.Get("/Users/{userId}/Items", s.wrapAuth("Users/{userId}/Items", s.handleUserItems))
	r.Get("/Users/{userId}/Items/Resume", s.wrapAuth("Users/{userId}/Items/Resume", s.handleResumeItems))
	r.Get("/Users/{userId}/Items/Latest", s.wrapAuth("Users/{userId}/Items/Latest", s.handleLatestItems))
	r.Get("/Users/{userId}/Items/NextUp", s.wrapAuth("Users/{userId}/Items/NextUp", s.handleNextUpItems))
	r.Get("/Users/{userId}/Items/Root", s.wrapAuth("Users/{userId}/Items/Root", s.handleUserItemsRoot))
	r.Get("/Users/{userId}/Items/{itemId}", s.wrapAuth("Users/{userId}/Items/{itemId}", s.handleGetUserItem))
	r.Get("/Items/{itemId}", s.wrapAuth("Items/{itemId}", s.handleGetItem))
	r.Get("/Items/{itemId}/Children", s.wrapAuth("Items/{itemId}/Children", s.handleItemChildren))
	r.Get("/Users/{userId}/Items/{itemId}/Children", s.wrapAuth("Users/{userId}/Items/{itemId}/Children", s.handleUserItemChildren))
	r.Get("/UserItems/{itemId}/UserData", s.wrapAuth("UserItems/{itemId}/UserData", s.handleUserItemsUserData))
	r.Get("/Items/{itemId}/UserData", s.wrapAuth("Items/{itemId}/UserData", s.handleGetUserData))
	r.Get("/Shows/{showId}/Seasons", s.wrapAuth("Shows/{showId}/Seasons", s.handleShowSeasons))
	r.Get("/Shows/{showId}/Episodes", s.wrapAuth("Shows/{showId}/Episodes", s.handleShowEpisodes))
	r.Get("/Shows/NextUp", s.wrapAuth("Shows/NextUp", s.handleNextUpItems))

	r.Get("/Items/{itemId}/Similar", s.wrapAuth("Items/{itemId}/Similar", s.handleItemSimilar))
	r.Get("/Items/{itemId}/LocalTrailers", s.wrapAuth("Items/{itemId}/LocalTrailers", s.handleEmptyItemQuery))
	r.Get("/Items/{itemId}/SpecialFeatures", s.wrapAuth("Items/{itemId}/SpecialFeatures", s.handleEmptyItemQuery))
	r.Get("/Items/{itemId}/ThemeMedia", s.wrapAuth("Items/{itemId}/ThemeMedia", s.handleEmptyItemQuery))
	r.Get("/Items/{itemId}/ThemeSongs", s.wrapAuth("Items/{itemId}/ThemeSongs", s.handleEmptyItemQuery))
	r.Get("/Items/{itemId}/Intros", s.wrapAuth("Items/{itemId}/Intros", s.handleEmptyItemQuery))
	r.Get("/Items/{itemId}/Chapters", s.wrapAuth("Items/{itemId}/Chapters", s.handleEmptyItemQuery))
	r.Get("/Items/{itemId}/AdditionalParts", s.wrapAuth("Items/{itemId}/AdditionalParts", s.handleEmptyItemQuery))

	r.Get("/LiveTv/Channels", s.wrapAuth("LiveTv/Channels", s.handleLiveTvChannels))
	r.Get("/LiveTv/Programs", s.wrapAuth("LiveTv/Programs", s.handleEmptyItemQuery))
	r.Get("/LiveTv/Recordings", s.wrapAuth("LiveTv/Recordings", s.handleEmptyItemQuery))

	r.Get("/Genres", s.wrapAuth("Genres", s.handleEmptyItemQuery))
	r.Get("/Years", s.wrapAuth("Years", s.handleEmptyItemQuery))

	r.Get("/Items/{itemId}/PlaybackInfo", s.wrapAuth("Items/{itemId}/PlaybackInfo GET", s.handleGetPlaybackInfo))
	r.Post("/Items/{itemId}/PlaybackInfo", s.wrapAuth("Items/{itemId}/PlaybackInfo POST", s.handlePostPlaybackInfo))
	r.Get("/Videos/{itemId}/stream", s.wrapAuth("Videos/{itemId}/stream", s.handleVideoStream))
	r.Get("/Videos/{itemId}/stream.{container}", s.wrapAuth("Videos/{itemId}/stream.container", s.handleVideoStream))

	r.Post("/Sessions/Playing", s.wrapAuth("Sessions/Playing", s.handlePlaying))
	r.Post("/Sessions/Playing/Start", s.wrapAuth("Sessions/Playing/Start", s.handlePlaying))
	r.Post("/Sessions/Playing/Progress", s.wrapAuth("Sessions/Playing/Progress", s.handlePlayingProgress))
	r.Post("/Sessions/Playing/Stopped", s.wrapAuth("Sessions/Playing/Stopped", s.handlePlayingStopped))
	r.Post("/Users/{userId}/PlayingItems/{itemId}/Progress", s.wrapAuth("Users/{userId}/PlayingItems/{itemId}/Progress", s.handleItemProgress))

	r.Get("/Items/{itemId}/Images/{imageType}", s.wrap("Items/{itemId}/Images/{imageType}", s.handleItemImage))
	r.Get("/Items/{itemId}/Images/{imageType}/{imageIndex}", s.wrap("Items/{itemId}/Images/{imageType}/{imageIndex}", s.handleItemImage))
	r.Get("/Persons/{personId}/Images/{imageType}", s.wrap("Persons/{personId}/Images/{imageType}", s.handlePersonImage))

	r.Get("/MediaSegments/{itemId}", s.wrapAuth("MediaSegments/{itemId}", s.handleMediaSegments))

	r.Get("/DisplayPreferences/usersettings", s.wrapAuth("DisplayPreferences/usersettings", s.handleDisplayPreferences))
	r.Post("/Sessions/Capabilities/Full", s.wrapAuth("Sessions/Capabilities/Full", s.handleSessionCapabilities))
	r.Post("/Sessions/Logout", s.wrapAuth("Sessions/Logout", s.handleLogout))
}

func (s *Server) handleNotFound(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet && (r.URL.Path == "/Items//" || r.URL.Path == "/Items/" || r.URL.Path == "/emby/Items//" || r.URL.Path == "/emby/Items/") {
		s.handleItemsEmptyQuery(w, r)
		return
	}
	jfLog(
		"404 unhandled path method=%s path=%s query=%s",
		r.Method,
		r.URL.Path,
		r.URL.RawQuery,
	)
	writeJSON(w, http.StatusNotFound, map[string]string{"error": "Not found"})
}

func (s *Server) handleUserViewsQuery(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	queryUserID := r.URL.Query().Get("userId")
	if queryUserID != "" && !userIDMatches(queryUserID, auth.Session.JellyfinUserID) {
		jfLog(
			"handleUserViewsQuery user mismatch queryUserId=%q sessionUserId=%q",
			queryUserID,
			auth.Session.JellyfinUserID,
		)
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	s.writeUserViews(w, auth)
}

func (s *Server) handleVirtualFolders(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	folders, err := s.virtualFolders(auth)
	if err != nil {
		jfLogError("handleVirtualFolders", "build_folders", err)
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "Unable to load library"})
		return
	}
	jfLog("handleVirtualFolders ok count=%d", len(folders))
	writeJSON(w, http.StatusOK, folders)
}

func (s *Server) handleRootFolder(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	item, err := s.rootFolderItem(auth)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "Unable to load root folder"})
		return
	}
	s.finalizeItem(&item, auth)
	writeJSON(w, http.StatusOK, item)
}

func userIDMatches(pathUserID, sessionUserID string) bool {
	if pathUserID == "" {
		return true
	}
	if strings.EqualFold(pathUserID, "Me") {
		return true
	}
	return normalizeID(pathUserID) == normalizeID(sessionUserID)
}

func nowRFC3339() string {
	return time.Now().UTC().Format(time.RFC3339Nano)
}
