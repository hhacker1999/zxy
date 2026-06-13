package jellyfin

import (
	"fmt"
	"strings"
)

func jellyfinUserItemKey(itemID string) string {
	id := strings.ReplaceAll(strings.ToLower(itemID), "-", "")
	if len(id) != 32 {
		return itemID
	}
	return fmt.Sprintf("%s-%s-%s-%s-%s", id[0:8], id[8:12], id[12:16], id[16:20], id[20:32])
}

func jellyfinItemID(itemID string) string {
	return strings.ReplaceAll(strings.ToLower(itemID), "-", "")
}

func applyJellyfinFolderDefaults(item *BaseItemDto) {
	if item == nil {
		return
	}
	item.CanDelete = false
	item.CanDownload = false
	item.EnableMediaSourceDisplay = true
	item.PlayAccess = "Full"
	item.LockData = false
	item.LocationType = "FileSystem"
	item.MediaType = "Unknown"
	if item.SortName == "" && item.Name != "" {
		item.SortName = strings.ToLower(item.Name)
	}
	if item.Path == "" && item.Id != "" {
		item.Path = fmt.Sprintf("/zxy/library/%s", jellyfinItemID(item.Id))
	}
	if item.People == nil {
		item.People = []PersonInfo{}
	}
	if item.Studios == nil {
		item.Studios = []NameGuidPair{}
	}
	if item.Tags == nil {
		item.Tags = []string{}
	}
	if item.Taglines == nil {
		item.Taglines = []string{}
	}
	if item.Genres == nil {
		item.Genres = []string{}
	}
	if item.BackdropImageTags == nil {
		item.BackdropImageTags = []string{}
	}
	if item.ProviderIds == nil {
		item.ProviderIds = map[string]string{}
	}
}

func applyJellyfinMediaDefaults(item *BaseItemDto) {
	if item == nil {
		return
	}
	item.CanDelete = false
	item.CanDownload = false
	item.LocationType = "FileSystem"
	if item.People == nil {
		item.People = []PersonInfo{}
	}
	if item.Studios == nil {
		item.Studios = []NameGuidPair{}
	}
	if item.Tags == nil {
		item.Tags = []string{}
	}
	if item.Taglines == nil {
		item.Taglines = []string{}
	}
	if item.BackdropImageTags == nil {
		item.BackdropImageTags = []string{}
	}
	if item.Genres == nil {
		item.Genres = []string{}
	}
	if item.MediaType == "" {
		switch strings.ToLower(item.Type) {
		case "movie", "episode", "video":
			item.MediaType = "Video"
		case "series", "season":
			item.MediaType = "Video"
		default:
			item.MediaType = "Video"
		}
	}
	if item.IsFolder {
		item.MediaType = "Unknown"
	}
	if item.SortName == "" && item.Name != "" {
		item.SortName = strings.ToLower(item.Name)
	}
	if strings.EqualFold(item.Type, "Movie") {
		if item.LocationType == "" {
			item.LocationType = "FileSystem"
		}
		if item.Container == "" {
			item.Container = "mkv"
		}
		item.HasSubtitles = true
		if item.VideoType == "" {
			item.VideoType = "VideoFile"
		}
		if item.Path == "" && item.Id != "" {
			item.Path = fmt.Sprintf("/zxy/media/%s", jellyfinItemID(item.Id))
		}
	}
}
