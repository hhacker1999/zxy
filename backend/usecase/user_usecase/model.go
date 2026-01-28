package userusecase

type CreateProfileInput struct {
	ProfileId            int    `json:"profile_id"`
	CreaterProfileId     int    `json:"-"`
	UserId               int    `json:"user_id"`
	Name                 string `json:"name"`
	UseDefaultProfileKey bool   `json:"use_default_profile_key"`
	Pin                  string `json:"pin"`
	IsAdmin              bool   `json:"is_admin"`
}
