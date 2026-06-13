package jellyfin

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
	"sync"
	"time"
	"zxy/models"
	"zxy/utils"
)

type authSession struct {
	Token          string
	UserId         int
	ProfileId      int
	JellyfinUserID string
	UserUUID       string
	UserName       string
	Email          string
	DeviceId       string
	DeviceName     string
	Client         string
	CreatedAt      time.Time
}

type authStore struct {
	mu       sync.RWMutex
	sessions map[string]*authSession
}

func newAuthStore() *authStore {
	return &authStore{sessions: make(map[string]*authSession)}
}

func (s *authStore) put(session *authSession) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.sessions[session.Token] = session
}

func (s *authStore) get(token string) (*authSession, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	session, ok := s.sessions[token]
	return session, ok
}

func (s *authStore) delete(token string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.sessions, token)
}

type authContext struct {
	Session *authSession
	Token   string
}

type authContextKey struct{}

var tokenPattern = regexp.MustCompile(`Token="([^"]+)"`)

func parseAuthToken(r *http.Request) string {
	if apiKey := r.URL.Query().Get("ApiKey"); apiKey != "" {
		return apiKey
	}
	if apiKey := r.URL.Query().Get("api_key"); apiKey != "" {
		return apiKey
	}
	for _, header := range []string{
		r.Header.Get("Authorization"),
		r.Header.Get("X-Emby-Authorization"),
		r.Header.Get("X-MediaBrowser-Authorization"),
	} {
		if header == "" {
			continue
		}
		if matches := tokenPattern.FindStringSubmatch(header); len(matches) == 2 {
			return matches[1]
		}
		if strings.HasPrefix(header, "MediaBrowser Token=") {
			return strings.Trim(strings.TrimPrefix(header, "MediaBrowser Token="), `"`)
		}
	}
	for _, header := range []string{"X-Emby-Token", "X-MediaBrowser-Token"} {
		if v := r.Header.Get(header); v != "" {
			return v
		}
	}
	return ""
}

func parseMediaBrowserHeader(r *http.Request) (client, device, deviceID, version string) {
	header := r.Header.Get("X-Emby-Authorization")
	if header == "" {
		header = r.Header.Get("X-MediaBrowser-Authorization")
	}
	if header == "" {
		header = r.Header.Get("Authorization")
	}
	for _, part := range strings.Split(header, ",") {
		part = strings.TrimSpace(part)
		kv := strings.SplitN(part, "=", 2)
		if len(kv) != 2 {
			continue
		}
		key := strings.TrimSpace(kv[0])
		val := strings.Trim(strings.TrimSpace(kv[1]), `"`)
		switch key {
		case "Client":
			client = val
		case "Device":
			device = val
		case "DeviceId":
			deviceID = val
		case "Version":
			version = val
		}
	}
	return
}

func (s *Server) authRequired(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		token := parseAuthToken(r)
		if token == "" {
			jfLog("auth middleware: missing token path=%s", r.URL.Path)
			jfLogAuthHeaders(r)
			writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
			return
		}
		session, ok := s.auth.get(token)
		if !ok {
			jfLog("auth middleware: unknown token path=%s tokenPrefix=%s", r.URL.Path, truncateForLog(token, 8))
			writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
			return
		}
		jfLog(
			"auth middleware: ok path=%s userId=%d profileId=%d jellyfinUserId=%s",
			r.URL.Path,
			session.UserId,
			session.ProfileId,
			session.JellyfinUserID,
		)
		ctx := withAuth(r, &authContext{Session: session, Token: token})
		next(w, ctx)
	}
}

func authFrom(r *http.Request) (*authContext, bool) {
	v := r.Context().Value(authContextKey{})
	if v == nil {
		return nil, false
	}
	auth, ok := v.(*authContext)
	return auth, ok
}

func withAuth(r *http.Request, auth *authContext) *http.Request {
	return r.WithContext(context.WithValue(r.Context(), authContextKey{}, auth))
}

func (s *Server) handleAuthenticateByName(w http.ResponseWriter, r *http.Request) {
	const handler = "Users/AuthenticateByName"

	body, err := io.ReadAll(r.Body)
	if err != nil {
		jfLogError(handler, "read_body", err)
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "Invalid request"})
		jfLogResponse(handler, http.StatusBadRequest, "read_body_failed")
		return
	}
	defer r.Body.Close()

	jfLog("login rawBodyLen=%d bodyPreview=%s", len(body), truncateForLog(string(body), 200))

	var req AuthenticateRequest
	if err := json.Unmarshal(body, &req); err != nil {
		jfLogError(handler, "unmarshal_body", err)
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "Invalid request"})
		jfLogResponse(handler, http.StatusBadRequest, "invalid_json")
		return
	}

	username := strings.TrimSpace(req.Username)
	client, device, deviceID, version := parseMediaBrowserHeader(r)
	password := req.Pw
	if password == "" {
		password = req.Password
	}
	jfLog(
		"login parsed username=%q hasPassword=%t client=%q device=%q deviceId=%q version=%q",
		username,
		password != "",
		client,
		device,
		deviceID,
		version,
	)

	if username == "" || password == "" {
		jfLog("login rejected: empty email or password usernameEmpty=%t passwordEmpty=%t", username == "", password == "")
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid email or password."})
		jfLogResponse(handler, http.StatusUnauthorized, "empty_credentials")
		return
	}
	if !strings.Contains(username, "@") {
		jfLog("login rejected: username is not an email username=%q", username)
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Use your zxy email address to sign in."})
		jfLogResponse(handler, http.StatusUnauthorized, "not_an_email")
		return
	}

	user, sessionToken, err := s.userUC.LogInUser(username, password)
	if err != nil {
		jfLogError(handler, "user_login", err)
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid email or password."})
		jfLogResponse(handler, http.StatusUnauthorized, "user_login_failed")
		return
	}
	jfLog(
		"login user ok userId=%d userUUID=%s profileCount=%d sessionTokenPrefix=%s",
		user.Id,
		user.UserId,
		len(user.Profiles),
		truncateForLog(sessionToken, 8),
	)

	profile, err := selectAdminProfile(user)
	if err != nil {
		jfLogError(handler, "select_admin_profile", err)
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": err.Error()})
		jfLogResponse(handler, http.StatusUnauthorized, "admin_profile_not_found")
		return
	}
	jfLog(
		"login admin profile selected profileId=%d profileName=%q isPinProtected=%t",
		profile.Id,
		profile.Name,
		profile.IsPinProtected,
	)

	userSession, err := s.sessionRepo.GetUserSession(sessionToken)
	if err != nil {
		jfLogError(handler, "get_user_session", err)
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "Authentication failed"})
		jfLogResponse(handler, http.StatusInternalServerError, "get_user_session_failed")
		return
	}
	jfLog("login user session loaded sessionId=%d userId=%d", userSession.Id, userSession.UserId)

	if err := s.loginAdminProfileForJellyfin(profile.Id, userSession.Id); err != nil {
		jfLogError(handler, "profile_session_create", err)
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Profile login failed"})
		jfLogResponse(handler, http.StatusUnauthorized, "profile_session_create_failed")
		return
	}
	jfLog("login profile session created profileId=%d sessionId=%d", profile.Id, userSession.Id)

	if client == "" {
		client = "Jellyfin Client"
	}
	if device == "" {
		device = "Unknown Device"
	}
	if deviceID == "" {
		deviceID = utils.GetRandomString(16)
	}
	if version == "" {
		version = "1.0.0"
	}

	accessToken := utils.GetRandomString(32)
	jellyfinUserID := s.items.userID(user.UserId)

	session := &authSession{
		Token:          accessToken,
		UserId:         user.Id,
		ProfileId:      profile.Id,
		JellyfinUserID: jellyfinUserID,
		UserUUID:       user.UserId,
		UserName:       user.Email,
		Email:          user.Email,
		DeviceId:       deviceID,
		DeviceName:     device,
		Client:         client,
		CreatedAt:      time.Now(),
	}
	s.auth.put(session)

	jfLog(
		"login success email=%q jellyfinUserId=%s accessTokenPrefix=%s profileId=%d",
		user.Email,
		jellyfinUserID,
		truncateForLog(accessToken, 8),
		profile.Id,
	)

	writeJSON(w, http.StatusOK, AuthenticationResult{
		User: UserDto{
			Name:                      user.Email,
			Id:                        jellyfinUserID,
			ServerId:                  s.serverID,
			HasPassword:               true,
			HasConfiguredPassword:     true,
			HasConfiguredEasyPassword: false,
			EnableAutoLogin:           false,
			LastLoginDate:             time.Now().UTC().Format(time.RFC3339),
			LastActivityDate:          time.Now().UTC().Format(time.RFC3339),
			Configuration:             defaultUserConfiguration(),
			Policy:                    defaultUserPolicy(),
		},
		SessionInfo: buildSessionInfo(session, client, device, deviceID, version, s.serverID, s.getRequestIP(r)),
		AccessToken: accessToken,
		ServerId:    s.serverID,
	})
	jfLogResponse(handler, http.StatusOK, "authenticated")
}

func selectAdminProfile(user models.User) (models.UserProfile, error) {
	jfLog("selectAdminProfile userId=%d profileCount=%d", user.Id, len(user.Profiles))
	for i := range user.Profiles {
		p := user.Profiles[i]
		jfLog(
			"selectAdminProfile candidate profileId=%d name=%q isAdmin=%t isPinProtected=%t",
			p.Id,
			p.Name,
			p.IsAdmin,
			p.IsPinProtected,
		)
		if p.IsAdmin {
			jfLog("selectAdminProfile selected profileId=%d", p.Id)
			return p, nil
		}
	}
	jfLog("selectAdminProfile no admin profile found userId=%d", user.Id)
	return models.UserProfile{}, fmt.Errorf("admin profile not found")
}

func (s *Server) loginAdminProfileForJellyfin(profileID, sessionID int) error {
	jfLog("loginAdminProfileForJellyfin profileId=%d sessionId=%d", profileID, sessionID)
	if err := s.sessionRepo.RemoveProfileSessions(context.Background(), profileID); err != nil {
		jfLogError("loginAdminProfileForJellyfin", "remove_profile_sessions", err)
		return err
	}
	token := utils.GetRandomString(50)
	err := s.sessionRepo.CreateProfileSession(context.Background(), models.ProfileSession{
		ProfileId:    profileID,
		SessionId:    sessionID,
		Token:        token,
		RefreshToken: token,
		Expiry:       time.Now(),
	})
	if err != nil {
		jfLogError("loginAdminProfileForJellyfin", "create_profile_session", err)
		return err
	}
	jfLog("loginAdminProfileForJellyfin success profileId=%d sessionId=%d", profileID, sessionID)
	return nil
}


func defaultUserPolicy() *UserPolicy {
	return &UserPolicy{
		IsAdministrator:                  true,
		IsHidden:                         false,
		IsDisabled:                       false,
		EnableUserPreferenceAccess:       true,
		EnableRemoteAccess:               true,
		EnableLiveTvManagement:           false,
		EnableLiveTvAccess:               false,
		EnableMediaPlayback:              true,
		EnableAudioPlaybackTranscoding:   false,
		EnableVideoPlaybackTranscoding:   false,
		EnablePlaybackRemuxing:           false,
		EnableContentDeletion:            false,
		EnableContentDownloading:         false,
		EnableSyncTranscoding:            false,
		EnableMediaConversion:            false,
		EnableAllDevices:                 true,
		EnableAllChannels:                true,
		EnableAllFolders:                 true,
		LoginAttemptsBeforeLockout:       -1,
		MaxActiveSessions:                0,
	}
}

func defaultUserConfiguration() *UserConfiguration {
	return &UserConfiguration{
		PlayDefaultAudioTrack:      true,
		SubtitleLanguagePreference: "",
		DisplayMissingEpisodes:     false,
		GroupedFolders:             []any{},
		SubtitleMode:               "Default",
		DisplayCollectionsView:     false,
		EnableLocalPassword:        false,
		OrderedViews:               []any{},
		LatestItemsExcludes:        []any{},
		MyMediaExcludes:            []any{},
		HidePlayedInLatest:         true,
		RememberAudioSelections:    true,
		RememberSubtitleSelections: true,
		EnableNextEpisodeAutoPlay:  true,
		CastReceiverId:             "F007D354",
	}
}

func buildSessionInfo(
	session *authSession,
	client, device, deviceID, version, serverID, remoteIP string,
) SessionInfo {
	now := time.Now().UTC().Format(time.RFC3339)
	return SessionInfo{
		Id:                       utils.GetRandomString(32),
		UserId:                   session.JellyfinUserID,
		UserName:                 session.UserName,
		Client:                   client,
		DeviceId:                 deviceID,
		DeviceName:               device,
		ApplicationVersion:       version,
		ServerId:                 serverID,
		IsActive:                 true,
		LastActivityDate:         now,
		LastPlaybackCheckIn:      "0001-01-01T00:00:00.0000000Z",
		RemoteEndPoint:           remoteIP,
		PlayableMediaTypes:       []string{},
		SupportedCommands:        []string{},
		SupportsMediaControl:     false,
		SupportsRemoteControl:    false,
		HasCustomDeviceName:      false,
		AdditionalUsers:          []any{},
		NowPlayingQueue:          []any{},
		NowPlayingQueueFullItems: []any{},
		PlayState: sessionPlayState{
			CanSeek:       false,
			IsPaused:      false,
			IsMuted:       false,
			RepeatMode:    "RepeatNone",
			PlaybackOrder: "Default",
		},
		Capabilities: sessionCapabilities{
			PlayableMediaTypes:           []string{},
			SupportedCommands:            []string{},
			SupportsMediaControl:         false,
			SupportsPersistentIdentifier: true,
		},
	}
}
