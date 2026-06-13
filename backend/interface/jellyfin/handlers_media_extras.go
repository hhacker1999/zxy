package jellyfin

import (
	"fmt"
	"net/http"

	"zxy/models"

	"github.com/go-chi/chi/v5"
)

func (s *Server) handleGetUserItem(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	if !s.ensureUser(r, auth) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "User not found"})
		return
	}
	s.serveGetItem(w, r, auth, chi.URLParam(r, "itemId"))
}

func (s *Server) serveGetItem(w http.ResponseWriter, r *http.Request, auth *authContext, itemID string) {
	if itemID == "" || itemID == "/" {
		item, err := s.rootFolderItem(auth)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "Unable to load item"})
			return
		}
		writeJSON(w, http.StatusOK, item)
		return
	}
	item, found, err := s.resolveItem(itemID, auth)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "Unable to load item"})
		return
	}
	if !found {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "Item not found"})
		return
	}
	s.finalizeItem(&item, auth)
	applyRequestedFields(&item, r)
	writeJSON(w, http.StatusOK, item)
}

func (s *Server) handleShowSeasons(w http.ResponseWriter, r *http.Request) {
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
	items, total := s.listSeasons(ref.ShowID, auth)
	start := queryInt(r, "StartIndex", 0)
	limit := queryInt(r, "Limit", 0)
	if start > 0 || limit > 0 {
		if start > len(items) {
			start = len(items)
		}
		end := len(items)
		if limit > 0 && start+limit < end {
			end = start + limit
		}
		items = items[start:end]
	}
	writeQueryResult(w, start, total, s.finalizeItems(items, auth))
}

func (s *Server) handleItemSimilar(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	itemID := chi.URLParam(r, "itemId")
	ref, ok := s.lookupItemRef(itemID, auth)
	if !ok {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "Item not found"})
		return
	}
	limit := queryInt(r, "Limit", 10)
	items, err := s.similarItems(ref, limit, auth)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "Unable to load similar items"})
		return
	}
	writeJSON(w, http.StatusOK, QueryResult{
		Items:            items,
		TotalRecordCount: len(items),
	})
}

func (s *Server) similarItems(ref MediaRef, limit int, auth *authContext) ([]BaseItemDto, error) {
	items := []BaseItemDto{}
	switch ref.Kind {
	case "movie":
		movie, err := s.tmdbUC.GetMovieDetails(fmt.Sprintf("%d", ref.TmdbID))
		if err != nil {
			return nil, err
		}
		for _, sim := range movie.Similar.Results {
			items = append(items, s.similarMovieItem(sim, auth))
			if limit > 0 && len(items) >= limit {
				return items, nil
			}
		}
		for _, rec := range movie.Recommendations.Results {
			items = append(items, s.similarMovieItem(rec, auth))
			if limit > 0 && len(items) >= limit {
				return items, nil
			}
		}
	case "series":
		show, err := s.tmdbUC.GetShowDetails(fmt.Sprintf("%d", ref.ShowID))
		if err != nil {
			return nil, err
		}
		for _, sim := range show.Similar.Results {
			items = append(items, s.similarShowItem(sim, auth))
			if limit > 0 && len(items) >= limit {
				return items, nil
			}
		}
		for _, rec := range show.Recommendations.Results {
			items = append(items, s.similarShowItem(rec, auth))
			if limit > 0 && len(items) >= limit {
				return items, nil
			}
		}
	}
	return items, nil
}

func (s *Server) similarMovieItem(sim models.SimilarResultMovie, auth *authContext) BaseItemDto {
	return s.movieItem(models.ZxyMedia{
		ID:          sim.ID,
		Title:       sim.Title,
		Overview:    sim.Overview,
		PosterPath:  sim.PosterPath,
		VoteAverage: sim.VoteAverage,
		ReleaseDate: strPtr(sim.ReleaseDate),
		Type:        "movie",
	}, auth)
}

func (s *Server) similarShowItem(sim models.SimilarResultShow, auth *authContext) BaseItemDto {
	return s.seriesItem(models.ZxyMedia{
		ID:           sim.ID,
		Name:         sim.Name,
		Overview:     sim.Overview,
		PosterPath:   sim.PosterPath,
		VoteAverage:  sim.VoteAverage,
		FirstAirDate: strPtr(sim.FirstAirDate),
		Type:         "series",
	}, auth)
}

func (s *Server) handleEmptyItemQuery(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	_ = auth
	writeJSON(w, http.StatusOK, QueryResult{
		Items:            []BaseItemDto{},
		TotalRecordCount: 0,
	})
}

func (s *Server) handleLiveTvChannels(w http.ResponseWriter, r *http.Request) {
	auth, ok := authFrom(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "Invalid token."})
		return
	}
	_ = auth
	writeJSON(w, http.StatusOK, QueryResult{
		Items:            []BaseItemDto{},
		TotalRecordCount: 0,
	})
}
