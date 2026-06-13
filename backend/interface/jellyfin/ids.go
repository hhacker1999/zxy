package jellyfin

import (
	"fmt"
	"strings"
	"sync"

	"zxy/models"

	"github.com/google/uuid"
)

const ticksPerSecond int64 = 10_000_000

var idNamespace = uuid.MustParse("f47ac10b-58cc-4372-a567-0e02b2c3d479")

var (
	IDUserRootView  = deriveID("view:root")
	defaultServerID = deriveID("zxy-jellyfin-server")
)

type MediaRef struct {
	Kind          string
	TmdbID        int64
	ShowID        int64
	Season        int
	Episode       int
	ImagePath     string
	PersonName    string
	LibraryFilter models.LibraryFilter
	RowName       string
}

type itemRegistry struct {
	mu   sync.RWMutex
	byID map[string]MediaRef
}

func newItemRegistry() *itemRegistry {
	r := &itemRegistry{byID: make(map[string]MediaRef)}
	r.register(IDUserRootView, MediaRef{Kind: "root"})
	return r
}

func (r *itemRegistry) register(id string, ref MediaRef) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.byID[id] = ref
}

func (r *itemRegistry) lookup(id string) (MediaRef, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if ref, ok := r.byID[id]; ok {
		return ref, true
	}
	normalized := normalizeID(id)
	if normalized == "" {
		return MediaRef{}, false
	}
	for key, ref := range r.byID {
		if normalizeID(key) == normalized {
			return ref, true
		}
	}
	return MediaRef{}, false
}

func deriveID(key string) string {
	return strings.ReplaceAll(uuid.NewSHA1(idNamespace, []byte(key)).String(), "-", "")
}

func normalizeID(id string) string {
	return strings.ReplaceAll(strings.ToLower(strings.TrimSpace(id)), "-", "")
}

func (r *itemRegistry) userID(userUUID string) string {
	id := deriveID("user:" + userUUID)
	r.register(id, MediaRef{Kind: "user"})
	return id
}

func (r *itemRegistry) movieID(tmdbID int64) string {
	id := deriveID(fmt.Sprintf("movie:%d", tmdbID))
	r.register(id, MediaRef{Kind: "movie", TmdbID: tmdbID})
	return id
}

func (r *itemRegistry) seriesID(tmdbID int64) string {
	id := deriveID(fmt.Sprintf("series:%d", tmdbID))
	r.register(id, MediaRef{Kind: "series", TmdbID: tmdbID, ShowID: tmdbID})
	return id
}

func (r *itemRegistry) seasonID(showID int64, season int) string {
	id := deriveID(fmt.Sprintf("season:%d:%d", showID, season))
	r.register(id, MediaRef{Kind: "season", ShowID: showID, TmdbID: showID, Season: season})
	return id
}

func (r *itemRegistry) episodeID(showID int64, season, episode int) string {
	id := deriveID(fmt.Sprintf("episode:%d:%d:%d", showID, season, episode))
	r.register(id, MediaRef{
		Kind:    "episode",
		ShowID:  showID,
		TmdbID:  showID,
		Season:  season,
		Episode: episode,
	})
	return id
}

func (r *itemRegistry) libraryRowID(profileID, index int, row models.ProfileLibraryItem) string {
	id := deriveID(fmt.Sprintf("libraryrow:%d:%d", profileID, index))
	r.register(id, MediaRef{
		Kind:          "library_row",
		LibraryFilter: row.Filter,
		RowName:       row.Name,
	})
	return id
}

func (r *itemRegistry) personID(tmdbPersonID int64, profilePath, name string) string {
	id := deriveID(fmt.Sprintf("person:%d", tmdbPersonID))
	r.register(id, MediaRef{
		Kind:       "person",
		TmdbID:     tmdbPersonID,
		ImagePath:  profilePath,
		PersonName: name,
	})
	return id
}

func mediaSourceID(itemID string) string {
	return deriveID("mediasource:" + itemID)
}

func ProgressMediaID(ref MediaRef) string {
	switch ref.Kind {
	case "movie":
		return fmt.Sprintf("%d", ref.TmdbID)
	case "episode":
		return fmt.Sprintf("%d:%d:%d", ref.ShowID, ref.Season, ref.Episode)
	default:
		return ""
	}
}

func SecondsToTicks(seconds int64) int64 {
	if seconds <= 0 {
		return 0
	}
	return seconds * ticksPerSecond
}

func PercentToTicks(percent float64, runtimeSeconds int64) int64 {
	if runtimeSeconds <= 0 || percent <= 0 {
		return 0
	}
	return int64(float64(runtimeSeconds) * float64(ticksPerSecond) * (percent / 100.0))
}

func TicksToPercent(ticks int64, runtimeSeconds int64) float64 {
	if runtimeSeconds <= 0 || ticks <= 0 {
		return 0
	}
	total := float64(runtimeSeconds) * float64(ticksPerSecond)
	return (float64(ticks) / total) * 100.0
}

func normalizeIncludeTypes(raw string) []string {
	if raw == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, strings.ToLower(p))
		}
	}
	return out
}
