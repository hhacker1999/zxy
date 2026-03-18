package progressusecase

import (
	"time"
	"zxy/models"
	playbackrepository "zxy/repository/playback_repository"
)

type TempProgress struct {
	MediaId   string    `json:"media_id"`
	Progress  float64   `json:"progress"`
	UpdatedAt time.Time `json:"updated_at"`
}

type ContinueWatchingItem struct {
	Progress playbackrepository.ProgressUpdate `json:"progress"`
	Media    models.ZxyMedia                   `json:"media"`
}
