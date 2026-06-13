package jellyfin

import (
	"net/http"

	"github.com/go-chi/chi/v5"
)

func (s *Server) handleSystemConfiguration(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, directPlayServerConfiguration())
}

func (s *Server) handleQuickConnectEnabled(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, false)
}

func (s *Server) handleEmptyArray(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, []any{})
}

func (s *Server) handleGetUserData(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	itemID := chi.URLParam(r, "itemId")
	if itemID == "" {
		itemID = r.URL.Query().Get("itemId")
	}
	ref, ok := s.lookupItemRef(itemID, auth)
	if !ok {
		writeJSON(w, http.StatusOK, emptyUserData(auth, itemID))
		return
	}
	runtime, _ := s.runtimeForRef(ref)
	writeJSON(
		w,
		http.StatusOK,
		s.userData(auth.Session.UserId, auth.Session.ProfileId, ref, runtime, itemID, auth),
	)
}

func (s *Server) handleUserItemsUserData(w http.ResponseWriter, r *http.Request) {
	s.handleGetUserData(w, r)
}

func (s *Server) handleEncodingOptions(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"EnableThrottling":                 false,
		"EnableFallbackFont":               false,
		"EnableAudioVbrEncoding":           false,
		"DisableVbrAudio":                  true,
		"EnableDebouncing":                 false,
		"MaxMuxingQueueSize":               2048,
		"EnableEnhancedNvdecDecoder":       false,
		"PreferSystemNativeHwDecoder":      true,
		"EnableIntelLowPowerH264HwEncoder": false,
		"EnableIntelLowPowerHevcHwEncoder": false,
		"AllowHevcEncoding":                false,
		"AllowAv1Encoding":                 false,
	})
}

func directPlayServerConfiguration() map[string]any {
	return map[string]any{
		"EnableUPnP":                         false,
		"EnableRemoteAccess":                 true,
		"EnableAutomaticRestart":             false,
		"EnableDashboardResponseCaching":     true,
		"MetadataCountryCode":                "US",
		"SortRemoveCharacters":               []string{},
		"SortReplaceCharacters":              []string{},
		"EnableCaseSensitiveItemIds":         true,
		"PreferredMetadataLanguage":          "en",
		"MetadataRefreshProportion":          0,
		"EnableTranscoding":                  false,
		"EnableNormalizedItemByNameIds":      true,
		"IsBehindProxy":                      false,
		"EnableFolderView":                   false,
		"EnableGroupingIntoCollections":      false,
		"DisplaySpecialsWithinSeasons":       true,
		"EnableExternalContentInSuggestions": false,
		"RequireHttps":                       false,
		"IsPortAuthorized":                   true,
		"QuickConnectAvailable":              false,
		"EnableSlowResponseWarning":          false,
		"SlowResponseThresholdMs":            500,
		"EnableLegacyAuthorization":          true,
	}
}
