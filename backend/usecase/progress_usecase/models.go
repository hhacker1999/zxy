package progressusecase

import "time"

type TempProgress struct {
	MediaId   string    `json:"media_id"`
	Progress  float64   `json:"progress"`
	UpdatedAt time.Time `json:"updated_at"`
}
