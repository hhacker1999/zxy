package models

import "time"

type AddonStreamResponse struct {
	Streams []AddonStream `json:"streams"`
}

type AddonStream struct {
	Name          string        `json:"name"`
	Description   string        `json:"description"`
	URL           string        `json:"url"`
	BehaviorHints BehaviorHints `json:"behaviorHints"`
}

type StreamResult struct {
	Name          string        `json:"name"`
	Description   string        `json:"description"`
	Url           string        `json:"url"`
	Resolution    string        `json:"resolution"`
	Container     string        `json:"container"`
	Language      string        `json:"language"`
	BehaviorHints BehaviorHints `json:"behaviorHints"`
}

type BehaviorHints struct {
	BingeGroup string `json:"bingeGroup"`
	VideoSize  int64  `json:"videoSize"`
	Filename   string `json:"filename"`
}

type Addon struct {
	Id          int       `json:"-"`
	ProfileId   int       `json:"profile_id"`
	ManifestUrl string    `json:"manifest_url"`
	AddedAt     time.Time `json:"added_at"`
	Enabled     bool      `json:"enabled"`
}

type AIOResponse struct {
	Success bool   `json:"success"`
	Detail  string `json:"detail"`
	Data    Data   `json:"data"`
	Error   string `json:"error"`
}

type Data struct {
	UUID              string `json:"uuid"`
	EncryptedPassword string `json:"encryptedPassword"`
}
