package jellyfin

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"zxy/models"
	progressusecase "zxy/usecase/progress_usecase"

	"github.com/go-chi/chi/v5"
)

func (s *Server) handleMediaFolders(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	items, err := s.libraryViewFolders(auth)
	if err != nil {
		jfLogError("handleMediaFolders", "library_view_folders", err)
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "Unable to load library"})
		return
	}
	jfLog("handleMediaFolders ok count=%d", len(items))
	writeQueryResult(w, 0, len(items), s.finalizeItems(items, auth))
}

func (s *Server) handleUserViews(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	if !s.ensureUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	s.writeUserViews(w, auth)
}

func (s *Server) handleUserItems(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok || !s.ensureUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	s.serveUserItems(w, r, auth)
}

func (s *Server) handleResumeItems(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok || !s.ensureUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	s.serveResumeItems(w, r, auth)
}

func (s *Server) handleLatestItems(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok || !s.ensureUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	s.serveLatestItems(w, r, auth)
}

func (s *Server) handleNextUpItems(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok || !s.ensureUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	startIndex := queryIntAny(r, 0, "StartIndex", "startIndex")
	limit := queryIntAny(r, 20, "Limit", "limit")
	if limit <= 0 {
		limit = 20
	}
	items, total := s.latestFromLibraryRows(auth, limit)
	items = s.finalizeItems(items, auth)
	writeQueryResult(w, startIndex, total, items)
}

func (s *Server) handleGetItem(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	itemID := chi.URLParam(r, "itemId")
	if strings.EqualFold(itemID, "Latest") {
		s.handleItemsLatestQuery(w, r)
		return
	}
	if strings.EqualFold(itemID, "Root") || normalizeID(itemID) == normalizeID(IDUserRootView) {
		item, err := s.rootFolderItem(auth)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "Unable to load item"})
			return
		}
		s.finalizeItem(&item, auth)
		writeJSON(w, http.StatusOK, item)
		return
	}
	s.serveGetItem(w, r, auth, itemID)
}

func (s *Server) handleShowEpisodes(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	showID := chi.URLParam(r, "showId")
	ref, ok := s.lookupItemRef(showID, auth)
	if !ok || ref.Kind != "series" {
		writeQueryResult(w, 0, 0, []BaseItemDto{})
		return
	}
	season := queryInt(r, "Season", 0)
	if season == 0 {
		season = queryInt(r, "season", 1)
	}
	items, _ := s.listEpisodes(ref.ShowID, season, auth)
	writeQueryResult(w, 0, len(items), s.finalizeItems(items, auth))
}

func (s *Server) ensureUser(r *http.Request, auth *authContext) bool {
	userID := chi.URLParam(r, "userId")
	if userIDMatches(userID, auth.Session.JellyfinUserID) {
		return true
	}
	jfLog(
		"ensureUser mismatch pathUserId=%q sessionUserId=%q path=%s",
		userID,
		auth.Session.JellyfinUserID,
		r.URL.Path,
	)
	return false
}

func hasType(types []string, target string) bool {
	if len(types) == 0 {
		return false
	}
	for _, t := range types {
		if t == strings.ToLower(target) {
			return true
		}
	}
	return false
}

func (s *Server) listMovies(page, limit int, auth *authContext) ([]BaseItemDto, int) {
	rows, err := s.profileLibraryRows(auth)
	if err != nil {
		return []BaseItemDto{}, 0
	}
	items := []BaseItemDto{}
	total := 0
	for i, row := range rows {
		if !row.Filter.IsMovie {
			continue
		}
		ref := MediaRef{Kind: "library_row", LibraryFilter: row.Filter, RowName: row.Name}
		rowID := s.items.libraryRowID(auth.Session.ProfileId, i, row)
		rowItems, rowTotal := s.listLibraryRowItems(ref, rowID, page, limit, auth)
		items = append(items, rowItems...)
		total += rowTotal
	}
	return items, total
}

func (s *Server) listSeries(page, limit int, auth *authContext) ([]BaseItemDto, int) {
	rows, err := s.profileLibraryRows(auth)
	if err != nil {
		return []BaseItemDto{}, 0
	}
	items := []BaseItemDto{}
	total := 0
	for i, row := range rows {
		if row.Filter.IsMovie {
			continue
		}
		ref := MediaRef{Kind: "library_row", LibraryFilter: row.Filter, RowName: row.Name}
		rowID := s.items.libraryRowID(auth.Session.ProfileId, i, row)
		rowItems, rowTotal := s.listLibraryRowItems(ref, rowID, page, limit, auth)
		items = append(items, rowItems...)
		total += rowTotal
	}
	return items, total
}

func (s *Server) searchItems(term string, includeTypes []string, page, limit int, auth *authContext) ([]BaseItemDto, int) {
	items := []BaseItemDto{}
	total := 0
	searchMovies := len(includeTypes) == 0 || hasType(includeTypes, "movie")
	searchSeries := len(includeTypes) == 0 || hasType(includeTypes, "series")
	if searchMovies {
		resp, err := s.tmdbUC.SearchMovie(page, term)
		if err == nil {
			for _, media := range resp.Results {
				items = append(items, s.movieItem(media, auth))
			}
			total += resp.TotalResults
		}
	}
	if searchSeries {
		resp, err := s.tmdbUC.SearchShows(page, term)
		if err == nil {
			for _, media := range resp.Results {
				items = append(items, s.seriesItem(media, auth))
			}
			total += resp.TotalResults
		}
	}
	return items, total
}

func (s *Server) listSeasons(showID int64, auth *authContext) ([]BaseItemDto, int) {
	show, err := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", showID))
	if err != nil {
		return []BaseItemDto{}, 0
	}
	items := make([]BaseItemDto, 0, len(show.Seasons))
	for _, season := range show.Seasons {
		if season.SeasonNumber == 0 {
			continue
		}
		items = append(items, s.seasonItem(show, season, auth))
	}
	return items, len(items)
}

func (s *Server) listEpisodes(showID int64, seasonNum int, auth *authContext) ([]BaseItemDto, int) {
	show, err := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", showID))
	if err != nil {
		return []BaseItemDto{}, 0
	}
	items := []BaseItemDto{}
	for _, season := range show.Seasons {
		if int(season.SeasonNumber) != seasonNum {
			continue
		}
		for _, episode := range season.Episodes {
			if episode.EpisodeNumber == 0 {
				continue
			}
			items = append(items, s.episodeItem(show, season, episode, auth))
		}
	}
	return items, len(items)
}

func (s *Server) resolveItem(itemID string, auth *authContext) (BaseItemDto, bool, error) {
	if itemID == IDUserRootView {
		return BaseItemDto{
			Name:       "Library",
			ServerId:   s.serverID,
			Id:         IDUserRootView,
			Type:       "UserView",
			IsFolder:   true,
			CollectionType: "mixed",
		}, true, nil
	}
	ref, ok := s.items.lookup(itemID)
	if !ok {
		ref, ok = s.lookupItemRef(itemID, auth)
	}
	if !ok {
		return BaseItemDto{}, false, nil
	}
	if ref.Kind == "library_row" {
		rows, err := s.profileLibraryRows(auth)
		if err != nil {
			return BaseItemDto{}, false, err
		}
	for i, row := range rows {
		if normalizeID(s.items.libraryRowID(auth.Session.ProfileId, i, row)) == normalizeID(itemID) {
			item := s.libraryRowFolder(auth, i, row)
			ref := MediaRef{
				Kind:          "library_row",
				LibraryFilter: row.Filter,
				RowName:       row.Name,
			}
			_, total := s.listLibraryRowItems(ref, itemID, 1, 1, auth)
			item.ChildCount = total
			applyJellyfinFolderDefaults(&item)
			return item, true, nil
		}
	}
	}
	switch ref.Kind {
	case "movie":
		movie, err := s.tmdbUC.GetMovieDetails(fmt.Sprintf("%d", ref.TmdbID))
		if err != nil {
			return BaseItemDto{}, false, err
		}
		return s.movieDetailItem(movie, auth), true, nil
	case "series":
		show, err := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", ref.TmdbID))
		if err != nil {
			return BaseItemDto{}, false, err
		}
		return s.seriesDetailItem(show, auth), true, nil
	case "season":
		show, err := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", ref.ShowID))
		if err != nil {
			return BaseItemDto{}, false, err
		}
		for _, season := range show.Seasons {
			if int(season.SeasonNumber) == ref.Season {
				return s.seasonItem(show, season, auth), true, nil
			}
		}
	case "episode":
		show, err := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", ref.ShowID))
		if err != nil {
			return BaseItemDto{}, false, err
		}
		for _, season := range show.Seasons {
			if int(season.SeasonNumber) != ref.Season {
				continue
			}
			for _, episode := range season.Episodes {
				if int(episode.EpisodeNumber) == ref.Episode {
					return s.episodeItem(show, season, episode, auth), true, nil
				}
			}
		}
	case "person":
		return s.personItem(itemID, ref, auth), true, nil
	}
	return BaseItemDto{}, false, nil
}

func (s *Server) personItem(itemID string, ref MediaRef, auth *authContext) BaseItemDto {
	item := BaseItemDto{
		Name:           ref.PersonName,
		ServerId:       s.serverID,
		Id:             itemID,
		Type:           "Person",
		IsFolder:       false,
		LocationType:   "Remote",
		DateCreated:    nowRFC3339(),
		ProviderIds: map[string]string{
			"Tmdb": fmt.Sprintf("%d", ref.TmdbID),
		},
		UserData: emptyUserData(auth, itemID),
	}
	if tag := imageTag(ref.ImagePath); tag != "" {
		item.ImageTags = map[string]string{"Primary": tag}
		item.PrimaryImageAspectRatio = 1
	}
	return item
}

func (s *Server) movieItem(media models.ZxyMedia, auth *authContext) BaseItemDto {
	id := s.items.movieID(media.ID)
	runtime := int64(7200)
	ref := MediaRef{Kind: "movie", TmdbID: media.ID}
	title := firstNonEmpty(media.Title, media.Name)
	item := BaseItemDto{
		Name:            title,
		SortName:        strings.ToLower(title),
		ServerId:        s.serverID,
		Id:              id,
		Type:            "Movie",
		MediaType:       "Video",
		IsFolder:        false,
		Overview:        media.Overview,
		ProductionYear:  yearFromMedia(media),
		CommunityRating: media.VoteAverage,
		ParentId:        IDUserRootView,
		DateCreated:     nowRFC3339(),
		LocationType:    "FileSystem",
		Path:            fmt.Sprintf("/zxy/media/%s", jellyfinItemID(id)),
		Container:       "mkv",
		HasSubtitles:    true,
		VideoType:       "VideoFile",
		RunTimeTicks:    SecondsToTicks(runtime),
		ProviderIds: map[string]string{
			"Tmdb":    fmt.Sprintf("%d", media.ID),
			"ZxyKind": "movie",
		},
		ImageTags:         posterAndBackdropTags(media.PosterPath, media.BackdropPath),
		BackdropImageTags: backdropTagsFromPath(media.BackdropPath),
		UserData:          s.userData(auth.Session.UserId, auth.Session.ProfileId, ref, runtime, id, auth),
	}
	if auth != nil {
		item.MediaSources = s.stubMediaSources(id, runtime, auth.Token)
		item.MediaSourceCount = len(item.MediaSources)
	}
	return item
}

func (s *Server) seriesItem(media models.ZxyMedia, auth *authContext) BaseItemDto {
	id := s.items.seriesID(media.ID)
	item := BaseItemDto{
		Name:            media.Name,
		ServerId:        s.serverID,
		Id:              id,
		Type:            "Series",
		MediaType:       "Video",
		IsFolder:        true,
		Overview:        media.Overview,
		ProductionYear:  yearFromMedia(media),
		CommunityRating: media.VoteAverage,
		ParentId:        IDUserRootView,
		DateCreated:     nowRFC3339(),
		LocationType:    "Remote",
		ProviderIds: map[string]string{
			"Tmdb":    fmt.Sprintf("%d", media.ID),
			"ZxyKind": "series",
		},
		ImageTags:         posterAndBackdropTags(media.PosterPath, media.BackdropPath),
		BackdropImageTags: backdropTagsFromPath(media.BackdropPath),
		UserData:          emptyUserData(auth, id),
	}
	return item
}

func (s *Server) movieDetailItem(movie models.TMDBMovie, auth *authContext) BaseItemDto {
	id := s.items.movieID(movie.ID)
	ref := MediaRef{Kind: "movie", TmdbID: movie.ID}
	runtime := movie.Runtime
	item := s.movieItem(models.ZxyMedia{
		ID:           movie.ID,
		Title:        movie.Title,
		Overview:     movie.Overview,
		PosterPath:   movie.PosterPath,
		VoteAverage:  movie.VoteAverage,
		ReleaseDate:  strPtr(movie.ReleaseDate),
	}, auth)
	item.Id = id
	item.RunTimeTicks = SecondsToTicks(runtime)
	item.Genres = mediaGenres(movie.Genres)
	item.PremiereDate = movie.ReleaseDate
	item.UserData = s.userData(auth.Session.UserId, auth.Session.ProfileId, ref, runtime, id, auth)
	enrichMovieMetadata(&item, movie)
	item.People = s.creditsToPeople(movie.Credits)
	item.MediaSources = s.stubMediaSources(id, runtime, auth.Token)
	item.MediaSourceCount = len(item.MediaSources)
	item.MediaStreams = item.MediaSources[0].MediaStreams
	item.VideoType = "VideoFile"
	return item
}

func (s *Server) seriesDetailItem(show models.TMDBShow, auth *authContext) BaseItemDto {
	id := s.items.seriesID(show.ID)
	item := s.seriesItem(models.ZxyMedia{
		ID:          show.ID,
		Name:        show.Name,
		Overview:    show.Overview,
		PosterPath:  show.PosterPath,
		VoteAverage: show.VoteAverage,
		FirstAirDate: strPtr(show.FirstAirDate),
	}, auth)
	item.Id = id
	item.ChildCount = countSeasons(show)
	item.RecursiveItemCount = int(show.NumberOfEpisodes)
	item.Genres = mediaGenres(show.Genres)
	item.PremiereDate = show.FirstAirDate
	item.Status = mapShowStatus(show.Status)
	item.EndDate = show.LastAirDate
	if tag, ok := item.ImageTags["Primary"]; ok {
		item.SeriesPrimaryImageTag = tag
	}
	enrichShowMetadata(&item, show)
	item.People = s.creditsToPeople(show.Credits)
	item.UserData.UnplayedItemCount = int(show.NumberOfEpisodes)
	return item
}

func (s *Server) seasonItem(show models.TMDBShow, season models.Season, auth *authContext) BaseItemDto {
	id := s.items.seasonID(show.ID, int(season.SeasonNumber))
	seriesID := s.items.seriesID(show.ID)
	seriesTag := imageTag(show.PosterPath)
	item := BaseItemDto{
		Name:         season.Name,
		ServerId:     s.serverID,
		Id:           id,
		Type:         "Season",
		IsFolder:     true,
		IndexNumber:  int(season.SeasonNumber),
		ParentId:     seriesID,
		SeriesId:     seriesID,
		SeriesName:   show.Name,
		Overview:     season.Overview,
		PremiereDate: season.AirDate,
		ProviderIds: map[string]string{
			"Tmdb":      fmt.Sprintf("%d", show.ID),
			"ZxyKind":   "season",
			"ZxySeason": fmt.Sprintf("%d", season.SeasonNumber),
		},
		ImageTags: map[string]string{
			"Primary": imageTag(season.PosterPath),
		},
		UserData:              emptyUserData(auth, id),
		ChildCount:            len(season.Episodes),
		SeriesPrimaryImageTag: seriesTag,
		LocationType:          "Remote",
	}
	return item
}

func (s *Server) episodeItem(show models.TMDBShow, season models.Season, episode models.Episode, auth *authContext) BaseItemDto {
	id := s.items.episodeID(show.ID, int(season.SeasonNumber), int(episode.EpisodeNumber))
	seriesID := s.items.seriesID(show.ID)
	seasonID := s.items.seasonID(show.ID, int(season.SeasonNumber))
	ref := MediaRef{
		Kind:    "episode",
		ShowID:  show.ID,
		TmdbID:  show.ID,
		Season:  int(season.SeasonNumber),
		Episode: int(episode.EpisodeNumber),
	}
	runtime := episode.Runtime
	item := BaseItemDto{
		Name:              episode.Name,
		ServerId:          s.serverID,
		Id:                id,
		Type:              "Episode",
		MediaType:         "Video",
		VideoType:         "VideoFile",
		IsFolder:          false,
		Overview:          episode.Overview,
		IndexNumber:       int(episode.EpisodeNumber),
		ParentIndexNumber: int(season.SeasonNumber),
		SeriesId:          seriesID,
		SeasonId:          seasonID,
		SeriesName:        show.Name,
		SeasonName:        season.Name,
		ParentId:          seasonID,
		PremiereDate:      episode.AirDate,
		RunTimeTicks:      SecondsToTicks(runtime),
		CommunityRating:   episode.VoteAverage,
		ProviderIds: map[string]string{
			"Tmdb":       fmt.Sprintf("%d", show.ID),
			"ZxyKind":    "episode",
			"ZxySeason":  fmt.Sprintf("%d", season.SeasonNumber),
			"ZxyEpisode": fmt.Sprintf("%d", episode.EpisodeNumber),
		},
		ImageTags: map[string]string{
			"Primary": imageTag(episode.StillPath),
		},
		SeriesPrimaryImageTag: imageTag(show.PosterPath),
		UserData:              s.userData(auth.Session.UserId, auth.Session.ProfileId, ref, runtime, id, auth),
		LocationType:          "Remote",
	}
	item.MediaSources = s.stubMediaSources(id, runtime, auth.Token)
	item.MediaSourceCount = len(item.MediaSources)
	item.MediaStreams = item.MediaSources[0].MediaStreams
	return item
}

func (s *Server) continueWatchingItem(entry progressusecase.ContinueWatchingItem, auth *authContext) (BaseItemDto, bool) {
	media := entry.Media
	progress := entry.Progress
	parts := strings.Split(progress.MediaId, ":")
	if len(parts) == 1 {
		movieID, err := strconv.ParseInt(parts[0], 10, 64)
		if err != nil {
			return BaseItemDto{}, false
		}
		item := s.movieItem(media, auth)
		item.Id = s.items.movieID(movieID)
		item.UserData = &UserItemDataDto{
			Played:                progress.IsWatched,
			PlaybackPositionTicks: PercentToTicks(progress.Progress, 7200),
			PlayedPercentage:      progress.Progress,
			LastPlayedDate:        formatTime(progress.UpdatedAt),
		}
		enrichUserData(item.UserData, auth, item.Id)
		return item, true
	}
	if len(parts) != 3 {
		return BaseItemDto{}, false
	}
	showID, _ := strconv.ParseInt(parts[0], 10, 64)
	season, _ := strconv.Atoi(parts[1])
	episode, _ := strconv.Atoi(parts[2])
	show, err := s.tmdbUC.GetShowDetails(parts[0])
	if err != nil {
		return BaseItemDto{}, false
	}
	for _, ses := range show.Seasons {
		if int(ses.SeasonNumber) != season {
			continue
		}
		for _, ep := range ses.Episodes {
			if int(ep.EpisodeNumber) == episode {
				item := s.episodeItem(show, ses, ep, auth)
				item.UserData = &UserItemDataDto{
					Played:                progress.IsWatched,
					PlaybackPositionTicks: PercentToTicks(progress.Progress, ep.Runtime),
					PlayedPercentage:      progress.Progress,
					LastPlayedDate:        formatTime(progress.UpdatedAt),
				}
				enrichUserData(item.UserData, auth, item.Id)
				return item, true
			}
		}
	}
	_ = showID
	return BaseItemDto{}, false
}

func yearFromMedia(media models.ZxyMedia) int {
	if media.ReleaseDate != nil {
		return mediaYear(*media.ReleaseDate)
	}
	if media.FirstAirDate != nil {
		return mediaYear(*media.FirstAirDate)
	}
	return 0
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if v != "" {
			return v
		}
	}
	return ""
}

func strPtr(v string) *string {
	if v == "" {
		return nil
	}
	return &v
}

func countSeasons(show models.TMDBShow) int {
	count := 0
	for _, season := range show.Seasons {
		if season.SeasonNumber > 0 {
			count++
		}
	}
	return count
}

func enrichMovieMetadata(item *BaseItemDto, movie models.TMDBMovie) {
	item.SortName = movie.Title
	item.OriginalTitle = movie.OriginalTitle
	item.DateLastSaved = nowRFC3339()
	item.ProductionLocations = productionCountryNames(movie.ProductionCountries)
	item.Studios = productionCompaniesToStudios(movie.ProductionCompanies)
	item.BackdropImageTags = backdropImageTags(movie.BackdropPath, movie.Images.Backdrops)
	applyBackdropToImageTags(item)
	if movie.Tagline != "" {
		item.Taglines = []string{movie.Tagline}
	}
	item.ProviderIds = movieProviderIds(movie)
}

func enrichShowMetadata(item *BaseItemDto, show models.TMDBShow) {
	item.SortName = show.Name
	item.OriginalTitle = show.OriginalName
	item.DateLastSaved = nowRFC3339()
	item.ProductionLocations = show.OriginCountry
	if len(item.ProductionLocations) == 0 {
		item.ProductionLocations = productionCountryNames(show.ProductionCountries)
	}
	item.Studios = networksToStudios(show.ProductionCompanies)
	item.BackdropImageTags = backdropImageTags(show.BackdropPath, show.Images.Backdrops)
	applyBackdropToImageTags(item)
	if show.Tagline != "" {
		item.Taglines = []string{show.Tagline}
	}
	item.ProviderIds = showProviderIds(show)
}

func movieProviderIds(movie models.TMDBMovie) map[string]string {
	ids := map[string]string{
		"Tmdb":    fmt.Sprintf("%d", movie.ID),
		"ZxyKind": "movie",
	}
	if movie.ImdbID != "" {
		ids["Imdb"] = movie.ImdbID
	} else if movie.ExternalIDS.ImdbID != "" {
		ids["Imdb"] = movie.ExternalIDS.ImdbID
	}
	return ids
}

func showProviderIds(show models.TMDBShow) map[string]string {
	ids := map[string]string{
		"Tmdb":    fmt.Sprintf("%d", show.ID),
		"ZxyKind": "series",
	}
	if show.ExternalIDS.ImdbID != "" {
		ids["Imdb"] = show.ExternalIDS.ImdbID
	}
	if show.ExternalIDS.TvdbID > 0 {
		ids["Tvdb"] = fmt.Sprintf("%d", show.ExternalIDS.TvdbID)
	}
	return ids
}

func productionCountryNames(countries []models.ProductionCountry) []string {
	out := make([]string, 0, len(countries))
	for _, c := range countries {
		if c.Name != "" {
			out = append(out, c.Name)
		}
	}
	return out
}

func productionCompaniesToStudios(companies []models.ProductionCompany) []NameGuidPair {
	out := make([]NameGuidPair, 0, len(companies))
	for _, c := range companies {
		if c.Name == "" {
			continue
		}
		out = append(out, NameGuidPair{
			Name: c.Name,
			Id:   deriveID("studio:" + c.Name),
		})
	}
	return out
}

func networksToStudios(networks []models.Network) []NameGuidPair {
	out := make([]NameGuidPair, 0, len(networks))
	for _, n := range networks {
		if n.Name == "" {
			continue
		}
		out = append(out, NameGuidPair{
			Name: n.Name,
			Id:   deriveID("studio:" + n.Name),
		})
	}
	return out
}

func (s *Server) creditsToPeople(credits models.Credits) []PersonInfo {
	people := make([]PersonInfo, 0, len(credits.Cast)+len(credits.Crew))
	seen := map[int64]struct{}{}
	for _, cast := range credits.Cast {
		if cast.Name == "" {
			continue
		}
		role := ""
		profilePath := ""
		if cast.Character != nil {
			role = *cast.Character
		}
		tag := ""
		if cast.ProfilePath != nil {
			profilePath = *cast.ProfilePath
			tag = imageTag(profilePath)
		}
		people = append(people, PersonInfo{
			Name:            cast.Name,
			Id:              s.items.personID(cast.ID, profilePath, cast.Name),
			Role:            role,
			Type:            "Actor",
			PrimaryImageTag: tag,
		})
		seen[cast.ID] = struct{}{}
	}
	for _, crew := range credits.Crew {
		if crew.Name == "" {
			continue
		}
		if _, ok := seen[crew.ID]; ok {
			continue
		}
		personType := "Unknown"
		if crew.KnownForDepartment != "" {
			personType = crew.KnownForDepartment
		}
		role := ""
		profilePath := ""
		if crew.Job != nil {
			role = *crew.Job
		}
		tag := ""
		if crew.ProfilePath != nil {
			profilePath = *crew.ProfilePath
			tag = imageTag(profilePath)
		}
		people = append(people, PersonInfo{
			Name:            crew.Name,
			Id:              s.items.personID(crew.ID, profilePath, crew.Name),
			Role:            role,
			Type:            personType,
			PrimaryImageTag: tag,
		})
	}
	return people
}

func posterAndBackdropTags(posterPath, backdropPath string) map[string]string {
	tags := map[string]string{}
	if tag := imageTag(posterPath); tag != "" {
		tags["Primary"] = tag
	}
	if tag := imageTag(backdropPath); tag != "" {
		tags["Backdrop"] = tag
	}
	return tags
}

func backdropTagsFromPath(backdropPath string) []string {
	if tag := imageTag(backdropPath); tag != "" {
		return []string{tag}
	}
	return nil
}

func applyBackdropToImageTags(item *BaseItemDto) {
	if item == nil || len(item.BackdropImageTags) == 0 {
		return
	}
	if item.ImageTags == nil {
		item.ImageTags = map[string]string{}
	}
	if _, ok := item.ImageTags["Backdrop"]; !ok {
		item.ImageTags["Backdrop"] = item.BackdropImageTags[0]
	}
}

func backdropImageTags(primary string, backdrops []models.Backdrop) []string {
	tags := []string{}
	if primary != "" {
		tags = append(tags, imageTag(primary))
	}
	for _, b := range backdrops {
		if b.FilePath == "" {
			continue
		}
		tag := imageTag(b.FilePath)
		if tag == "" {
			continue
		}
		if len(tags) > 0 && tags[0] == tag {
			continue
		}
		tags = append(tags, tag)
		if len(tags) >= 3 {
			break
		}
	}
	return tags
}
