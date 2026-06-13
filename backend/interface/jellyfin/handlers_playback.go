package jellyfin

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"path/filepath"
	"strings"
	"zxy/models"

	"github.com/go-chi/chi/v5"
)

var streamProxyClient = &http.Client{
	Timeout: 0,
}

func (s *Server) handleGetPlaybackInfo(w http.ResponseWriter, r *http.Request) {
	s.servePlaybackInfo(w, r, nil)
}

func (s *Server) handlePostPlaybackInfo(w http.ResponseWriter, r *http.Request) {
	body, _ := io.ReadAll(r.Body)
	defer r.Body.Close()
	var req PlaybackInfoRequest
	if len(body) > 0 {
		_ = json.Unmarshal(body, &req)
	}
	s.servePlaybackInfo(w, r, &req)
}

func (s *Server) servePlaybackInfo(w http.ResponseWriter, r *http.Request, req *PlaybackInfoRequest) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}

	itemID := chi.URLParam(r, "itemId")
	jfLog("servePlaybackInfo itemId=%s", itemID)
	ref, ok := s.lookupItemRef(itemID, auth)
	if !ok || (ref.Kind != "movie" && ref.Kind != "episode") {
		jfLog("servePlaybackInfo item not playable itemId=%s kind=%q found=%t", itemID, ref.Kind, ok)
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "Item not found"})
		return
	}

	mediaSource := s.buildMediaSource(itemID, ref, auth)

	jfLog(
		"servePlaybackInfo ok itemId=%s kind=%s container=%s path=%s",
		itemID,
		ref.Kind,
		mediaSource.Container,
		truncateForLog(mediaSource.Path, 120),
	)

	writeJSON(w, http.StatusOK, PlaybackInfoResponse{
		MediaSources:  []MediaSourceInfo{mediaSource},
		PlaySessionId: fmt.Sprintf("zxy-%s", itemID),
	})
}

func (s *Server) buildMediaSource(itemID string, ref MediaRef, auth *authContext) MediaSourceInfo {
	runtime := int64(7200)
	switch ref.Kind {
	case "movie":
		if movie, err := s.tmdbUC.GetMovieDetails(fmt.Sprintf("%d", ref.TmdbID)); err == nil && movie.Runtime > 0 {
			runtime = movie.Runtime
		}
	case "episode":
		if show, err := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", ref.ShowID)); err == nil {
			for _, season := range show.Seasons {
				if int(season.SeasonNumber) != ref.Season {
					continue
				}
				for _, episode := range season.Episodes {
					if int(episode.EpisodeNumber) == ref.Episode && episode.Runtime > 0 {
						runtime = episode.Runtime
						break
					}
				}
			}
		}
	}

	cacheKey := fmt.Sprintf("%d:%d:%s", auth.Session.UserId, auth.Session.ProfileId, itemID)
	s.cacheStream(cacheKey, cachedStream{
		URL:       hardcodedPlaybackURL,
		FinalURL:  hardcodedPlaybackURL,
		Container: "mkv",
		Name:      "The Gorge",
	})

	playURL := s.streamURL(itemID, auth.Token)
	return MediaSourceInfo{
		Id:                   mediaSourceID(itemID),
		Path:                 playURL,
		DirectStreamUrl:      hardcodedPlaybackURL,
		Protocol:             "Http",
		Name:                 "The Gorge",
		Container:            "mkv",
		RunTimeTicks:         SecondsToTicks(runtime),
		SupportsDirectPlay:   true,
		SupportsDirectStream: true,
		SupportsTranscoding:  false,
		SupportsProbing:      false,
		IsRemote:             true,
		RequiresOpening:      false,
		RequiresClosing:      false,
		RequiresLooping:      false,
		ReadAtNativeFramerate: false,
		Type:                 "Default",
		MediaStreams: []MediaStreamInfo{
			{Codec: "hevc", Type: "Video", Index: 0, IsDefault: true},
		},
	}
}

func (s *Server) fetchBestStream(r *http.Request, auth *authContext, ref MediaRef) (models.ZxyResolutionResponse, int64, string, error) {
	userIP := s.getRequestIP(r)
	var streams models.ZxyStreamsRes
	var runtime int64
	var err error

	switch ref.Kind {
	case "movie":
		streams, err = s.addonUC.GetMovieStreamZxy(
			fmt.Sprintf("%d", ref.TmdbID),
			auth.Session.UserId,
			auth.Session.ProfileId,
			userIP,
			"",
		)
		if err == nil {
			movie, movieErr := s.tmdbUC.GetMovieDetails(fmt.Sprintf("%d", ref.TmdbID))
			if movieErr == nil {
				runtime = movie.Runtime
			}
		}
	case "episode":
		streams, err = s.addonUC.GetSeriesStreamZxy(
			fmt.Sprintf("%d", ref.ShowID),
			ref.Season,
			ref.Episode,
			auth.Session.UserId,
			auth.Session.ProfileId,
			userIP,
			"",
		)
		if err == nil {
			show, showErr := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", ref.ShowID))
			if showErr == nil {
				for _, season := range show.Seasons {
					if int(season.SeasonNumber) != ref.Season {
						continue
					}
					for _, episode := range season.Episodes {
						if int(episode.EpisodeNumber) == ref.Episode {
							runtime = episode.Runtime
							break
						}
					}
				}
			}
		}
	default:
		return models.ZxyResolutionResponse{}, 0, "", fmt.Errorf("unsupported item type")
	}
	if err != nil {
		jfLogError("fetchBestStream", ref.Kind, err)
		return models.ZxyResolutionResponse{}, 0, "", fmt.Errorf("stream lookup failed")
	}

	stream, ok := pickBestStream(streams)
	if !ok {
		jfLog("fetchBestStream no streams available kind=%s tmdbId=%d", ref.Kind, ref.TmdbID)
		return models.ZxyResolutionResponse{}, 0, "", fmt.Errorf("no streams available")
	}
	jfLog(
		"fetchBestStream ok kind=%s file=%q urlPrefix=%s",
		ref.Kind,
		stream.FileName,
		truncateForLog(stream.Url, 80),
	)
	container := detectContainer(stream)
	if runtime <= 0 {
		runtime = 7200
	}
	return stream, runtime, container, nil
}

func pickBestStream(streams models.ZxyStreamsRes) (models.ZxyResolutionResponse, bool) {
	for _, bucket := range [][]models.ZxyResolutionResponse{streams.FHD, streams.UHD, streams.HD} {
		if len(bucket) > 0 {
			return bucket[0], true
		}
	}
	return models.ZxyResolutionResponse{}, false
}

func detectContainer(stream models.ZxyResolutionResponse) string {
	name := strings.ToLower(stream.FileName)
	ext := strings.ToLower(filepath.Ext(name))
	switch ext {
	case ".mkv":
		return "mkv"
	case ".mp4":
		return "mp4"
	case ".avi":
		return "avi"
	default:
		return "mp4"
	}
}

func (s *Server) handleVideoStream(w http.ResponseWriter, r *http.Request) {
	if _, ok := authFrom(r); !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	itemID := chi.URLParam(r, "itemId")
	jfLog("handleVideoStream redirect itemId=%s url=%s", itemID, hardcodedPlaybackURL)
	http.Redirect(w, r, hardcodedPlaybackURL, http.StatusFound)
}

func (s *Server) resolvePlayableURL(zxyStreamURL string) (string, error) {
	if s.resolveStream == nil {
		return "", fmt.Errorf("stream resolver not configured")
	}
	parsed, err := url.Parse(zxyStreamURL)
	if err != nil {
		return "", err
	}
	internal := parsed.Query().Get("internal")
	if internal == "" {
		return zxyStreamURL, nil
	}
	return s.resolveStream(internal)
}

func (s *Server) proxyHTTPStream(w http.ResponseWriter, r *http.Request, upstreamURL string) {
	req, err := http.NewRequestWithContext(r.Context(), http.MethodGet, upstreamURL, nil)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": "Unable to open stream"})
		return
	}
	if rangeHeader := r.Header.Get("Range"); rangeHeader != "" {
		req.Header.Set("Range", rangeHeader)
	}
	if userIP := s.getRequestIP(r); userIP != "" {
		req.Header.Set("X-Forwarded-For", userIP)
		req.Header.Set("X-Real-IP", userIP)
		req.Header.Set("X-Client-Ip", userIP)
	}

	resp, err := streamProxyClient.Do(req)
	if err != nil {
		jfLogError("proxyHTTPStream", "upstream_request", err)
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": "Stream unavailable"})
		return
	}
	defer resp.Body.Close()

	for _, header := range []string{
		"Content-Type",
		"Content-Length",
		"Content-Range",
		"Accept-Ranges",
		"Cache-Control",
		"ETag",
		"Last-Modified",
	} {
		if value := resp.Header.Get(header); value != "" {
			w.Header().Set(header, value)
		}
	}
	w.WriteHeader(resp.StatusCode)
	if _, err := io.Copy(w, resp.Body); err != nil {
		jfLogError("proxyHTTPStream", "copy_body", err)
	}
}

func (s *Server) handlePlaying(w http.ResponseWriter, r *http.Request) {
	writeEmpty(w, http.StatusNoContent)
}

func (s *Server) handlePlayingProgress(w http.ResponseWriter, r *http.Request) {
	s.updateProgressFromBody(w, r)
}

func (s *Server) handlePlayingStopped(w http.ResponseWriter, r *http.Request) {
	s.updateProgressFromBody(w, r)
}

func (s *Server) handleItemProgress(w http.ResponseWriter, r *http.Request) {
	s.updateProgressFromBody(w, r)
}

func (s *Server) updateProgressFromBody(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "Invalid body"})
		return
	}
	defer r.Body.Close()

	itemID := chi.URLParam(r, "itemId")
	var payload ProgressPayload
	if err := json.Unmarshal(body, &payload); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "Invalid body"})
		return
	}
	if itemID != "" {
		payload.ItemId = itemID
	}
	if payload.ItemId == "" {
		writeEmpty(w, http.StatusNoContent)
		return
	}

	ref, ok := s.items.lookup(payload.ItemId)
	if !ok {
		writeEmpty(w, http.StatusNoContent)
		return
	}

	runtime, err := s.runtimeForRef(ref)
	if err != nil || runtime <= 0 {
		runtime = 7200
	}
	percent := TicksToPercent(payload.PositionTicks, runtime)
	if percent < 0 {
		percent = 0
	}
	if percent > 100 {
		percent = 100
	}

	mediaID := ProgressMediaID(ref)
	if mediaID == "" {
		writeEmpty(w, http.StatusNoContent)
		return
	}

	_ = s.progressUC.UpdatePlaybackProgress(
		auth.Session.UserId,
		auth.Session.ProfileId,
		mediaID,
		percent,
	)
	jfLog(
		"updateProgress itemId=%s mediaId=%s percent=%.2f positionTicks=%d",
		payload.ItemId,
		mediaID,
		percent,
		payload.PositionTicks,
	)
	writeEmpty(w, http.StatusNoContent)
}

func (s *Server) runtimeForRef(ref MediaRef) (int64, error) {
	switch ref.Kind {
	case "movie":
		movie, err := s.tmdbUC.GetMovieDetails(fmt.Sprintf("%d", ref.TmdbID))
		if err != nil {
			return 0, err
		}
		return movie.Runtime, nil
	case "episode":
		show, err := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", ref.ShowID))
		if err != nil {
			return 0, err
		}
		for _, season := range show.Seasons {
			if int(season.SeasonNumber) != ref.Season {
				continue
			}
			for _, episode := range season.Episodes {
				if int(episode.EpisodeNumber) == ref.Episode {
					return episode.Runtime, nil
				}
			}
		}
	}
	return 0, fmt.Errorf("runtime unavailable")
}

func (s *Server) stubMediaSources(itemID string, runtime int64, token string) []MediaSourceInfo {
	return []MediaSourceInfo{{
		Id:                   mediaSourceID(itemID),
		Path:                 s.streamURL(itemID, token),
		DirectStreamUrl:      hardcodedPlaybackURL,
		Protocol:             "Http",
		Container:            "mkv",
		SupportsDirectPlay:   true,
		SupportsDirectStream: true,
		SupportsTranscoding:  false,
		SupportsProbing:      false,
		IsRemote:             true,
		Type:                 "Default",
		RunTimeTicks:         SecondsToTicks(runtime),
		MediaStreams: []MediaStreamInfo{
			{Codec: "hevc", Type: "Video", Index: 0, IsDefault: true},
		},
	}}
}

func (s *Server) handleItemImage(w http.ResponseWriter, r *http.Request) {
	itemID := chi.URLParam(r, "itemId")
	imageType := chi.URLParam(r, "imageType")
	s.serveItemImage(w, r, itemID, imageType)
}

func (s *Server) handlePersonImage(w http.ResponseWriter, r *http.Request) {
	personID := chi.URLParam(r, "personId")
	imageType := chi.URLParam(r, "imageType")
	s.serveItemImage(w, r, personID, imageType)
}

func (s *Server) serveItemImage(w http.ResponseWriter, r *http.Request, itemID, imageType string) {
	refKind := ""
	imagePath := ""
	if ref, ok := s.items.lookup(itemID); ok {
		refKind = ref.Kind
		imagePath = s.imagePathForRef(ref, imageType)
	}
	if imagePath == "" {
		imagePath = imagePathFromTag(r.URL.Query().Get("tag"))
	}
	if imagePath == "" {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "Image not found"})
		return
	}
	size := tmdbImageSize(imageType, refKind)
	target := tmdbImageURL(s.imageBase, imagePath, size)
	if target == "" {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "Image not found"})
		return
	}
	s.proxyRemoteImage(w, r, target)
}

func (s *Server) proxyRemoteImage(w http.ResponseWriter, r *http.Request, target string) {
	req, err := http.NewRequestWithContext(r.Context(), http.MethodGet, target, nil)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": "Image fetch failed"})
		return
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": "Image fetch failed"})
		return
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "Image not found"})
		return
	}
	if ct := resp.Header.Get("Content-Type"); ct != "" {
		w.Header().Set("Content-Type", ct)
	} else {
		w.Header().Set("Content-Type", "image/jpeg")
	}
	w.Header().Set("Cache-Control", "public, max-age=86400")
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, resp.Body)
}

func (s *Server) handleMediaSegments(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	_ = auth
	writeJSON(w, http.StatusOK, []any{})
}

func (s *Server) imagePathForRef(ref MediaRef, imageType string) string {
	switch ref.Kind {
	case "person":
		return ref.ImagePath
	case "movie":
		movie, err := s.tmdbUC.GetMovieDetails(fmt.Sprintf("%d", ref.TmdbID))
		if err != nil {
			return ""
		}
		if strings.EqualFold(imageType, "Backdrop") {
			if movie.BackdropPath != "" {
				return movie.BackdropPath
			}
			if len(movie.Images.Backdrops) > 0 {
				return movie.Images.Backdrops[0].FilePath
			}
		}
		return movie.PosterPath
	case "series":
		show, err := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", ref.TmdbID))
		if err != nil {
			return ""
		}
		if strings.EqualFold(imageType, "Backdrop") {
			if show.BackdropPath != "" {
				return show.BackdropPath
			}
			if len(show.Images.Backdrops) > 0 {
				return show.Images.Backdrops[0].FilePath
			}
		}
		return show.PosterPath
	case "season":
		show, err := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", ref.ShowID))
		if err != nil {
			return ""
		}
		for _, season := range show.Seasons {
			if int(season.SeasonNumber) == ref.Season {
				return season.PosterPath
			}
		}
	case "episode":
		show, err := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", ref.ShowID))
		if err != nil {
			return ""
		}
		for _, season := range show.Seasons {
			if int(season.SeasonNumber) != ref.Season {
				continue
			}
			for _, episode := range season.Episodes {
				if int(episode.EpisodeNumber) == ref.Episode {
					return episode.StillPath
				}
			}
		}
	}
	return ""
}
