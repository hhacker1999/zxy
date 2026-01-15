package playbackrepository

import "time"

type ProgressUpdate struct {
	MediaId   string
	Progress  float64
	UserId    int
	ProfileId int
	IsWatched bool
  CreatedAt time.Time
  UpdatedAt time.Time
}
