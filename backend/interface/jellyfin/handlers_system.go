package jellyfin

import (
	"encoding/hex"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
	"zxy/models"
	playbackrepository "zxy/repository/playback_repository"

	"github.com/go-chi/chi/v5"
)

const serverVersion = "10.10.7"
const serverName = "Zxy"

func (s *Server) systemInfo(localAddress string) SystemInfo {
	return SystemInfo{
		ServerName:                   serverName,
		Version:                      serverVersion,
		Id:                           s.serverID,
		OperatingSystem:              "Linux",
		LocalAddress:                 localAddress,
		StartupWizardCompleted:       true,
		HasPendingRestart:            false,
		CanSelfRestart:               false,
		CanLaunchWebBrowser:          false,
		HasUpdateAvailable:           false,
		HasConfigurablePlugins:       false,
		HasConfigurableLiveTvTuners:  false,
		IsProductionEnvironment:      false,
		SupportsLibraryMonitor:       false,
		SupportsContentDownloading:   true,
		SupportsMediaControl:         true,
		SupportsPersistentIdentifier: true,
		SupportsSyncTranscoding:      false,
	}
}

func (s *Server) handleSystemInfoPublic(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, PublicSystemInfo{
		ServerName:             serverName,
		ProductName:            "ZXY Fin Server",
		Version:                serverVersion,
		Id:                     s.serverID,
		StartupWizardCompleted: true,
		LocalAddress:           s.publicURL,
	})
}

func (s *Server) handleSystemInfo(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, s.systemInfo(s.publicURL))
}

func (s *Server) handleSystemEndpoint(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, EndpointInfo{
		IsLocal:       false,
		IsInNetwork:   true,
		ServerAddress: s.publicURL,
	})
}

func (s *Server) handleSystemPing(w http.ResponseWriter, r *http.Request) {
	writeEmpty(w, http.StatusOK)
}

func (s *Server) handleBrandingConfiguration(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, BrandingConfiguration{
		SplashscreenEnabled: false,
		LoginDisclaimer:     "",
	})
}

func (s *Server) handleUsersPublic(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, []UserDto{})
}

func (s *Server) handleUsersMe(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		jfLog("handleUsersMe missing auth context")
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	jfLog("handleUsersMe email=%q jellyfinUserId=%s", auth.Session.Email, auth.Session.JellyfinUserID)
	writeJSON(w, http.StatusOK, s.userDto(auth.Session))
}

func (s *Server) handleGetUserByID(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	userID := chi.URLParam(r, "userId")
	if !userIDMatches(userID, auth.Session.JellyfinUserID) {
		jfLog("handleGetUserByID mismatch pathUserId=%q sessionUserId=%q", userID, auth.Session.JellyfinUserID)
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	writeJSON(w, http.StatusOK, s.userDto(auth.Session))
}

func (s *Server) userDto(session *authSession) UserDto {
	name := session.Email
	if name == "" {
		name = session.UserName
	}
	return UserDto{
		Name:                      name,
		Id:                        session.JellyfinUserID,
		ServerId:                  s.serverID,
		HasPassword:               true,
		HasConfiguredPassword:     true,
		HasConfiguredEasyPassword: false,
		EnableAutoLogin:           false,
		LastLoginDate:             session.CreatedAt.UTC().Format(time.RFC3339),
		LastActivityDate:          time.Now().UTC().Format(time.RFC3339),
		Configuration:             defaultUserConfiguration(),
		Policy:                    defaultUserPolicy(),
	}
}

func (s *Server) handleDisplayPreferences(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	client := r.URL.Query().Get("client")
	if client == "" {
		client = "emby"
	}
	writeJSON(w, http.StatusOK, DisplayPreferences{
		Id:                 auth.Session.JellyfinUserID + "-usersettings-" + client,
		Client:             client,
		UserId:             auth.Session.JellyfinUserID,
		CustomPrefs:        map[string]string{},
		SortBy:             "SortName",
		SortOrder:          "Ascending",
		RememberSorting:    false,
		RememberIndexing:   false,
		PrimaryImageHeight: 250,
		PrimaryImageWidth:  250,
		ScrollDirection:    "Horizontal",
		ShowBackdrop:       true,
		ShowSidebar:        false,
	})
}

func (s *Server) handleSessionCapabilities(w http.ResponseWriter, r *http.Request) {
	writeEmpty(w, http.StatusNoContent)
}

func (s *Server) handleLogout(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if ok {
		jfLog("handleLogout userId=%d tokenPrefix=%s", auth.Session.UserId, truncateForLog(auth.Token, 8))
		s.auth.delete(auth.Token)
	}
	writeEmpty(w, http.StatusNoContent)
}


func (s *Server) userData(
	userID, profileID int,
	ref MediaRef,
	runtimeSeconds int64,
	itemID string,
	auth *authContext,
) *UserItemDataDto {
	mediaID := ProgressMediaID(ref)
	if mediaID == "" {
		return emptyUserData(auth, itemID)
	}
	var progress playbackrepository.ProgressUpdate
	var err error
	if ref.Kind == "movie" {
		progress, err = s.progressUC.GetMovieProgress(userID, profileID, mediaID)
	} else if ref.Kind == "episode" {
		items, err2 := s.progressUC.GetShowProgress(userID, profileID, fmt.Sprintf("%d", ref.ShowID))
		if err2 == nil {
			for _, item := range items {
				if item.MediaId == mediaID {
					progress = item
					break
				}
			}
		}
		err = err2
	}
	if err != nil {
		return emptyUserData(auth, itemID)
	}
	ticks := PercentToTicks(progress.Progress, runtimeSeconds)
	ud := &UserItemDataDto{
		Played:                progress.IsWatched,
		PlaybackPositionTicks: ticks,
		PlayCount:             boolToInt(progress.IsWatched),
		IsFavorite:            false,
		PlayedPercentage:      progress.Progress,
		LastPlayedDate:        formatTime(progress.UpdatedAt),
	}
	enrichUserData(ud, auth, itemID)
	return ud
}

func boolToInt(v bool) int {
	if v {
		return 1
	}
	return 0
}

func formatTime(t time.Time) string {
	if t.IsZero() {
		return ""
	}
	return t.UTC().Format(time.RFC3339)
}

func queryInt(r *http.Request, key string, fallback int) int {
	return queryIntAny(r, fallback, key)
}

func queryIntAny(r *http.Request, fallback int, keys ...string) int {
	raw := queryParam(r, keys...)
	if raw == "" {
		return fallback
	}
	v, err := strconv.Atoi(raw)
	if err != nil {
		return fallback
	}
	return v
}

func queryParam(r *http.Request, keys ...string) string {
	q := r.URL.Query()
	for _, key := range keys {
		if v := q.Get(key); v != "" {
			return v
		}
	}
	for k, vals := range q {
		for _, key := range keys {
			if strings.EqualFold(k, key) && len(vals) > 0 && vals[0] != "" {
				return vals[0]
			}
		}
	}
	return ""
}

func ensureQueryUser(r *http.Request, auth *authContext) bool {
	userID := queryParam(r, "userId", "UserId")
	if userID == "" {
		return true
	}
	if userIDMatches(userID, auth.Session.JellyfinUserID) {
		return true
	}
	jfLog(
		"ensureQueryUser mismatch queryUserId=%q sessionUserId=%q path=%s",
		userID,
		auth.Session.JellyfinUserID,
		r.URL.Path,
	)
	return false
}

func tmdbImageURL(base, path string, size string) string {
	if path == "" {
		return ""
	}
	if strings.HasPrefix(path, "http") {
		return path
	}
	if size == "" {
		size = "w500"
	}
	return fmt.Sprintf("%s/%s%s", strings.TrimRight(base, "/"), size, path)
}

func mediaGenres(genres []models.Genre) []string {
	out := make([]string, 0, len(genres))
	for _, g := range genres {
		out = append(out, g.Name)
	}
	return out
}

func mediaYear(date string) int {
	if len(date) < 4 {
		return 0
	}
	year, _ := strconv.Atoi(date[:4])
	return year
}

func imageTag(path string) string {
	if path == "" {
		return ""
	}
	return fmt.Sprintf("%x", path)
}

func imagePathFromTag(tag string) string {
	if tag == "" {
		return ""
	}
	decoded, err := hex.DecodeString(tag)
	if err != nil {
		return ""
	}
	path := string(decoded)
	if path == "" {
		return ""
	}
	if path[0] != '/' {
		path = "/" + path
	}
	return path
}

func tmdbImageSize(imageType string, refKind string) string {
	switch strings.ToLower(imageType) {
	case "backdrop":
		return "w1280"
	case "thumb":
		return "w300"
	default:
		if refKind == "person" {
			return "w300"
		}
		return "w500"
	}
}
