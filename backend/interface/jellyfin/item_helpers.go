package jellyfin

import (
	"crypto/sha1"
	"fmt"
	"net/http"
	"strings"
)

const primaryPosterAspectRatio = 0.6666666666666666

func userDataKey(userID, itemID string) string {
	_ = userID
	return jellyfinUserItemKey(itemID)
}

func itemEtag(id string) string {
	sum := sha1.Sum([]byte(id))
	return fmt.Sprintf("%x", sum)
}

func jellyfinDate(date string) string {
	if date == "" {
		return ""
	}
	if strings.Contains(date, "T") {
		return date
	}
	return date + "T00:00:00.0000000Z"
}

func emptyUserData(auth *authContext, itemID string) *UserItemDataDto {
	ud := &UserItemDataDto{
		Played:                false,
		PlaybackPositionTicks: 0,
		PlayCount:             0,
		IsFavorite:            false,
	}
	if auth != nil && itemID != "" {
		ud.Key = jellyfinUserItemKey(itemID)
		ud.ItemId = jellyfinItemID(itemID)
	}
	return ud
}

func enrichUserData(ud *UserItemDataDto, auth *authContext, itemID string) {
	if ud == nil {
		return
	}
	if auth != nil && itemID != "" {
		ud.Key = jellyfinUserItemKey(itemID)
		ud.ItemId = jellyfinItemID(itemID)
	}
}

func (s *Server) finalizeItem(item *BaseItemDto, auth *authContext) {
	if item == nil {
		return
	}
	if item.ServerId == "" {
		item.ServerId = s.serverID
	}
	if item.Id != "" && item.Etag == "" {
		item.Etag = itemEtag(item.Id)
	}
	if item.PremiereDate != "" {
		item.PremiereDate = jellyfinDate(item.PremiereDate)
	}
	if item.DateCreated != "" {
		item.DateCreated = jellyfinDate(item.DateCreated)
	} else if item.Id != "" {
		item.DateCreated = nowRFC3339()
	}
	if item.DateLastSaved != "" {
		item.DateLastSaved = jellyfinDate(item.DateLastSaved)
	}
	if item.EndDate != "" {
		item.EndDate = jellyfinDate(item.EndDate)
	}
	if item.ImageTags != nil {
		for key, tag := range item.ImageTags {
			if tag == "" {
				delete(item.ImageTags, key)
			}
		}
		if len(item.ImageTags) == 0 {
			item.ImageTags = nil
		}
	}
	if item.PrimaryImageAspectRatio == 0 && item.ImageTags != nil {
		if _, ok := item.ImageTags["Primary"]; ok {
			item.PrimaryImageAspectRatio = primaryPosterAspectRatio
		}
	}
	if item.UserData == nil {
		item.UserData = emptyUserData(auth, item.Id)
	} else {
		enrichUserData(item.UserData, auth, item.Id)
	}
	switch item.Type {
	case "CollectionFolder", "UserView", "UserRootFolder":
		applyJellyfinFolderDefaults(item)
	default:
		if !item.IsFolder {
			applyJellyfinMediaDefaults(item)
		}
	}
	if auth != nil && strings.EqualFold(item.Type, "Movie") && len(item.MediaSources) == 0 {
		runtime := int64(7200)
		if item.RunTimeTicks > 0 {
			runtime = item.RunTimeTicks / ticksPerSecond
		}
		item.MediaSources = s.stubMediaSources(item.Id, runtime, auth.Token)
		item.MediaSourceCount = len(item.MediaSources)
	}
}

func (s *Server) finalizeItems(items []BaseItemDto, auth *authContext) []BaseItemDto {
	if items == nil {
		items = []BaseItemDto{}
	}
	for i := range items {
		s.finalizeItem(&items[i], auth)
	}
	return items
}

func writeQueryResult(w http.ResponseWriter, startIndex, total int, items []BaseItemDto) {
	if items == nil {
		items = []BaseItemDto{}
	}
	writeJSON(w, http.StatusOK, QueryResult{
		Items:            items,
		TotalRecordCount: total,
		StartIndex:       startIndex,
	})
}

func writeItemArray(w http.ResponseWriter, items []BaseItemDto) {
	if items == nil {
		items = []BaseItemDto{}
	}
	writeJSON(w, http.StatusOK, items)
}

func applyRequestedFields(item *BaseItemDto, r *http.Request) {
	fields := strings.ToLower(queryParam(r, "Fields", "fields"))
	if fields == "" {
		return
	}
	if strings.Contains(fields, "mediastreams") && len(item.MediaSources) > 0 {
		item.MediaStreams = item.MediaSources[0].MediaStreams
		item.MediaSourceCount = len(item.MediaSources)
	}
}

func wantsOnlyIncludeTypes(includeTypes []string, target string) bool {
	if len(includeTypes) == 0 {
		return false
	}
	for _, t := range includeTypes {
		if t != target {
			return false
		}
	}
	return true
}

func mapShowStatus(status string) string {
	switch strings.ToLower(status) {
	case "ended", "canceled", "cancelled":
		return "Ended"
	case "returning series", "in production", "planned":
		return "Continuing"
	default:
		if status == "" {
			return "Continuing"
		}
		return status
	}
}
