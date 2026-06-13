package jellyfin

import (
	"encoding/json"
	"fmt"
	"net/http"

	"zxy/models"
)

func (s *Server) profileLibraryRows(auth *authContext) ([]models.ProfileLibraryItem, error) {
	jfLog(
		"profileLibraryRows userId=%d profileId=%d",
		auth.Session.UserId,
		auth.Session.ProfileId,
	)
	profile, err := s.userUC.GetUserProfile(auth.Session.UserId, auth.Session.ProfileId)
	if err != nil {
		jfLogError("profileLibraryRows", "get_user_profile", err)
		return nil, err
	}
	if len(profile.LibraryItems) == 0 {
		jfLog("profileLibraryRows using default library rows count=%d", len(models.DefaultLibraryItems))
		return models.DefaultLibraryItems, nil
	}
	jfLog("profileLibraryRows loaded custom rows count=%d", len(profile.LibraryItems))
	return profile.LibraryItems, nil
}

func (s *Server) libraryViewFolders(auth *authContext) ([]BaseItemDto, error) {
	rows, err := s.profileLibraryRows(auth)
	if err != nil {
		return nil, err
	}
	items := make([]BaseItemDto, 0, len(rows))
	for i, row := range rows {
		item := s.libraryRowFolder(auth, i, row)
		ref := MediaRef{
			Kind:          "library_row",
			LibraryFilter: row.Filter,
			RowName:       row.Name,
		}
		_, total := s.listLibraryRowItems(ref, item.Id, 1, 1, auth)
		item.ChildCount = total
		applyJellyfinFolderDefaults(&item)
		items = append(items, item)
	}
	return items, nil
}

func (s *Server) virtualFolders(auth *authContext) ([]VirtualFolderInfo, error) {
	rows, err := s.profileLibraryRows(auth)
	if err != nil {
		return nil, err
	}
	folders := make([]VirtualFolderInfo, 0, len(rows))
	for i, row := range rows {
		id := s.items.libraryRowID(auth.Session.ProfileId, i, row)
		collectionType := "tvshows"
		if row.Filter.IsMovie {
			collectionType = "movies"
		}
		folders = append(folders, VirtualFolderInfo{
			Name:               row.Name,
			Locations:          []string{},
			CollectionType:     collectionType,
			ItemId:             id,
			PrimaryImageItemId: id,
			RefreshStatus:      "Idle",
		})
	}
	return folders, nil
}

func (s *Server) rootFolderItem(auth *authContext) (BaseItemDto, error) {
	rows, err := s.profileLibraryRows(auth)
	if err != nil {
		return BaseItemDto{}, err
	}
	return BaseItemDto{
		Name:           "root",
		ServerId:       s.serverID,
		Id:             IDUserRootView,
		Type:           "UserRootFolder",
		IsFolder:       true,
		ChildCount:     len(rows),
		DateCreated:    nowRFC3339(),
		CollectionType: "mixed",
	}, nil
}

func (s *Server) writeUserViews(w http.ResponseWriter, auth *authContext) {
	items, err := s.libraryViewFolders(auth)
	if err != nil {
		jfLogError("writeUserViews", "library_view_folders", err)
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "Unable to load library"})
		return
	}
	jfLog("writeUserViews ok count=%d", len(items))
	items = s.finalizeItems(items, auth)
	writeQueryResult(w, 0, len(items), items)
}

func (s *Server) libraryRowFolder(auth *authContext, index int, row models.ProfileLibraryItem) BaseItemDto {
	id := s.items.libraryRowID(auth.Session.ProfileId, index, row)
	collectionType := "tvshows"
	if row.Filter.IsMovie {
		collectionType = "movies"
	}
	return BaseItemDto{
		Name:                 row.Name,
		ServerId:             s.serverID,
		Id:                   id,
		Type:                 "CollectionFolder",
		IsFolder:             true,
		CollectionType:       collectionType,
		DisplayPreferencesId: id,
		ParentId:             IDUserRootView,
		DateCreated:          nowRFC3339(),
		LocationType:         "FileSystem",
		UserData:             emptyUserData(auth, id),
	}
}

func (s *Server) listLibraryRowItems(ref MediaRef, parentID string, page, limit int, auth *authContext) ([]BaseItemDto, int) {
	filter := ref.LibraryFilter
	filter.Page = page
	if limit > 0 {
		filter.Items = limit
	}
	if filter.Items == 0 {
		filter.Items = 20
	}

	raw, err := s.tmdbUC.GetLibraryFromFilter(
		auth.Session.UserId,
		auth.Session.ProfileId,
		filter,
	)
	if err != nil {
		jfLogError("listLibraryRowItems", "get_library_from_filter", err)
		jfLog(
			"listLibraryRowItems failed row=%q type=%s isMovie=%t page=%d limit=%d",
			ref.RowName,
			filter.Type,
			filter.IsMovie,
			page,
			limit,
		)
		return []BaseItemDto{}, 0
	}

	resp, err := parseLibraryResult(raw)
	if err != nil {
		jfLogError("listLibraryRowItems", "parse_library_result", err)
		return []BaseItemDto{}, 0
	}

	jfLog(
		"listLibraryRowItems ok row=%q type=%s isMovie=%t page=%d results=%d total=%d",
		ref.RowName,
		filter.Type,
		filter.IsMovie,
		page,
		len(resp.Results),
		resp.TotalResults,
	)

	items := make([]BaseItemDto, 0, len(resp.Results))
	for _, media := range resp.Results {
		if filter.IsMovie || media.Type == "movie" {
			item := s.movieItem(media, auth)
			item.ParentId = parentID
			items = append(items, item)
			continue
		}
		item := s.seriesItem(media, auth)
		item.ParentId = parentID
		items = append(items, item)
	}

	total := resp.TotalResults
	if total == 0 {
		total = len(items)
	}
	return items, total
}

func (s *Server) latestFromLibraryRows(auth *authContext, limit int) ([]BaseItemDto, int) {
	rows, err := s.profileLibraryRows(auth)
	if err != nil {
		return []BaseItemDto{}, 0
	}

	items := []BaseItemDto{}
	seen := map[string]struct{}{}
	perRow := limit/len(rows) + 1
	if perRow < 1 {
		perRow = 1
	}

	for i, row := range rows {
		ref := MediaRef{
			Kind:          "library_row",
			LibraryFilter: row.Filter,
			RowName:       row.Name,
		}
		_ = s.items.libraryRowID(auth.Session.ProfileId, i, row)
		rowID := s.items.libraryRowID(auth.Session.ProfileId, i, row)
		rowItems, _ := s.listLibraryRowItems(ref, rowID, 1, perRow, auth)
		for _, item := range rowItems {
			if _, ok := seen[item.Id]; ok {
				continue
			}
			seen[item.Id] = struct{}{}
			items = append(items, item)
			if len(items) >= limit {
				return items, len(items)
			}
		}
	}
	return items, len(items)
}

func (s *Server) lookupItemRef(itemID string, auth *authContext) (MediaRef, bool) {
	if ref, ok := s.items.lookup(itemID); ok {
		return ref, true
	}
	rows, err := s.profileLibraryRows(auth)
	if err != nil {
		return MediaRef{}, false
	}
	for i, row := range rows {
		rowID := s.items.libraryRowID(auth.Session.ProfileId, i, row)
		if normalizeID(rowID) == normalizeID(itemID) {
			return s.items.lookup(rowID)
		}
	}
	return MediaRef{}, false
}

func parseLibraryResult(raw any) (models.MediaPaginatedResponse, error) {
	switch v := raw.(type) {
	case models.MediaPaginatedResponse:
		return v, nil
	case []byte:
		var res models.MediaPaginatedResponse
		if err := json.Unmarshal(v, &res); err != nil {
			return models.MediaPaginatedResponse{}, fmt.Errorf("parse library response: %w", err)
		}
		return res, nil
	default:
		return models.MediaPaginatedResponse{}, fmt.Errorf("unexpected library response type")
	}
}
