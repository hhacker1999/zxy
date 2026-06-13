package jellyfin

import (
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
)

func (s *Server) handleItemsLatestQuery(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	if !ensureQueryUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	s.serveLatestItems(w, r, auth)
}

func (s *Server) handleItemsEmptyQuery(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	if !ensureQueryUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	writeQueryResult(w, 0, 0, []BaseItemDto{})
}

func (s *Server) serveLatestItems(w http.ResponseWriter, r *http.Request, auth *authContext) {
	parentID := queryParam(r, "ParentId", "parentId")
	startIndex := queryIntAny(r, 0, "StartIndex", "startIndex")
	limit := queryIntAny(r, 20, "Limit", "limit")
	if limit <= 0 {
		limit = 20
	}
	page := startIndex/limit + 1
	if page < 1 {
		page = 1
	}

	var items []BaseItemDto
	total := 0

	switch {
	case parentID == "" || normalizeID(parentID) == normalizeID(IDUserRootView):
		items, total = s.latestFromLibraryRows(auth, limit)
	default:
		ref, ok := s.lookupItemRef(parentID, auth)
		if !ok || ref.Kind != "library_row" {
			writeItemArray(w, s.finalizeItems([]BaseItemDto{}, auth))
			return
		}
		items, total = s.listLibraryRowItems(ref, parentID, page, limit, auth)
	}

	_ = total
	items = s.finalizeItems(items, auth)
	writeItemArray(w, items)
}

func (s *Server) handleItemsQuery(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	if !ensureQueryUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	s.serveUserItems(w, r, auth)
}

func (s *Server) handleUserItemsResumeQuery(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	if !ensureQueryUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	s.serveResumeItems(w, r, auth)
}

func (s *Server) serveUserItems(w http.ResponseWriter, r *http.Request, auth *authContext) {
	parentID := queryParam(r, "ParentId", "parentId")
	searchTerm := queryParam(r, "SearchTerm", "searchTerm")
	includeTypes := normalizeIncludeTypes(queryParam(r, "IncludeItemTypes", "includeItemTypes"))
	startIndex := queryIntAny(r, 0, "StartIndex", "startIndex")
	limit := queryIntAny(r, 50, "Limit", "limit")
	if limit <= 0 {
		limit = 50
	}
	page := startIndex/limit + 1
	if page < 1 {
		page = 1
	}

	jfLog(
		"serveUserItems parentId=%q search=%q includeTypes=%v startIndex=%d limit=%d page=%d path=%s",
		parentID,
		searchTerm,
		includeTypes,
		startIndex,
		limit,
		page,
		r.URL.Path,
	)

	var items []BaseItemDto
	total := 0

	switch {
	case searchTerm != "":
		items, total = s.searchItems(searchTerm, includeTypes, page, limit, auth)
	case parentID == "" || normalizeID(parentID) == normalizeID(IDUserRootView):
		var err error
		items, err = s.libraryViewFolders(auth)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "Unable to load library"})
			return
		}
		total = len(items)
	default:
		ref, ok := s.lookupItemRef(parentID, auth)
		if !ok {
			jfLog("serveUserItems unknown parentId=%q returning empty list", parentID)
			writeJSON(w, http.StatusOK, QueryResult{Items: []BaseItemDto{}, TotalRecordCount: 0, StartIndex: startIndex})
			return
		}
		switch ref.Kind {
		case "library_row":
			items, total = s.listLibraryRowItems(ref, parentID, page, limit, auth)
		case "series":
			seasonNum := queryIntAny(r, 0, "SeasonId", "seasonId", "Season", "season")
			if seasonNum > 0 || wantsOnlyIncludeTypes(includeTypes, "episode") {
				if seasonNum <= 0 {
					seasonNum = 1
				}
				items, total = s.listEpisodes(ref.ShowID, seasonNum, auth)
			} else {
				items, total = s.listSeasons(ref.ShowID, auth)
			}
		case "season":
			items, total = s.listEpisodes(ref.ShowID, ref.Season, auth)
		default:
			items = []BaseItemDto{}
		}
	}

	items = filterItemsByTypes(items, includeTypes)

	if startIndex > 0 && startIndex < len(items) {
		items = items[startIndex:]
	}
	if len(items) > limit {
		items = items[:limit]
	}
	if total == 0 {
		total = len(items)
	}
	if items == nil {
		items = []BaseItemDto{}
	}
	items = s.finalizeItems(items, auth)

	writeQueryResult(w, startIndex, total, items)
	jfLog("serveUserItems ok items=%d total=%d", len(items), total)
}

func (s *Server) serveResumeItems(w http.ResponseWriter, r *http.Request, auth *authContext) {
	limit := queryIntAny(r, 15, "limit", "Limit")

	resume, err := s.progressUC.GetContinueWatching(auth.Session.UserId, auth.Session.ProfileId)
	if err != nil {
		jfLogError("serveResumeItems", "get_continue_watching", err)
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "Unable to load resume items"})
		return
	}

	items := make([]BaseItemDto, 0, len(resume))
	for _, entry := range resume {
		item, ok := s.continueWatchingItem(entry, auth)
		if ok {
			items = append(items, item)
		}
	}
	if len(items) > limit {
		items = items[:limit]
	}
	jfLog("serveResumeItems ok items=%d", len(items))
	writeJSON(w, http.StatusOK, QueryResult{
		Items:            items,
		TotalRecordCount: len(items),
	})
}

func filterItemsByTypes(items []BaseItemDto, includeTypes []string) []BaseItemDto {
	if len(includeTypes) == 0 {
		return items
	}
	filtered := make([]BaseItemDto, 0, len(items))
	for _, item := range items {
		if itemMatchesTypes(item, includeTypes) {
			filtered = append(filtered, item)
		}
	}
	return filtered
}

func itemMatchesTypes(item BaseItemDto, includeTypes []string) bool {
	itemType := strings.ToLower(item.Type)
	for _, want := range includeTypes {
		want = strings.ToLower(want)
		switch want {
		case "video":
			if itemType == "movie" || itemType == "episode" || strings.EqualFold(item.MediaType, "Video") {
				return true
			}
		case "movie":
			if itemType == "movie" {
				return true
			}
		case "series":
			if itemType == "series" {
				return true
			}
		case "episode":
			if itemType == "episode" {
				return true
			}
		case "season":
			if itemType == "season" {
				return true
			}
		case "collectionfolder", "folder", "userview":
			if item.IsFolder {
				return true
			}
		default:
			if itemType == want {
				return true
			}
		}
	}
	return false
}

func (s *Server) handleUserItemsRoot(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok || !s.ensureUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
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

func (s *Server) handleItemChildren(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	parentID := chi.URLParam(r, "itemId")
	q := r.URL.Query()
	q.Set("ParentId", parentID)
	r.URL.RawQuery = q.Encode()
	s.serveUserItems(w, r, auth)
}

func (s *Server) handleUserItemChildren(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok || !s.ensureUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	s.handleItemChildren(w, r)
}
