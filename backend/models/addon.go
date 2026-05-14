package models

import (
	"time"
)

type AddonStreamResponse struct {
	Streams   []AddonStream   `json:"streams"`
	Subtitles []AddonSubtitle `json:"subtitles"`
}

type AddonStream struct {
	Name          string        `json:"name"`
	Description   string        `json:"description"`
	URL           string        `json:"url"`
	BehaviorHints BehaviorHints `json:"behaviorHints"`
	StreamData    StreamData    `json:"streamData"`
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

type ZxyStreamsRes struct {
	UHD       []ZxyResolutionResponse `json:"uhd"`
	FHD       []ZxyResolutionResponse `json:"fhd"`
	HD        []ZxyResolutionResponse `json:"hd"`
	Subtitles []AddonSubtitle         `json:"subtitles"`
}

type ZxyResolutionResponse struct {
	VisualTags    []string `json:"visual_tags"`
	AudioTags     []string `json:"audio_tags"`
	FileName      string   `json:"file_name"`
	LanguageCodes []string `json:"language_codes"`
	Size          int      `json:"size"`
	Url           string   `json:"url"`
	Quality       string   `json:"quality"`
	Resolution    string   `json:"resolution"`
	Name          string   `json:"name"`
	Description   string   `json:"description"`
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

type StreamData struct {
	Type       string     `json:"type"`
	Proxied    bool       `json:"proxied,omitempty"`
	Indexer    string     `json:"indexer,omitempty"`
	Duration   float64    `json:"duration,omitempty"`
	Library    bool       `json:"library,omitempty"`
	Size       int64      `json:"size,omitempty"`
	Addon      string     `json:"addon"`
	Filename   string     `json:"filename,omitempty"`
	Service    Service    `json:"service"`
	ParsedFile ParsedFile `json:"parsedFile"`
	ID         string     `json:"id"`
}

type ErrorClass struct {
	Title       string `json:"title"`
	Description string `json:"description"`
}

type ParsedFile struct {
	Title         string   `json:"title"`
	Year          string   `json:"year"`
	Resolution    string   `json:"resolution"`
	Quality       string   `json:"quality,omitempty"`
	ReleaseGroup  string   `json:"releaseGroup,omitempty"`
	Container     string   `json:"container"`
	Extension     string   `json:"extension,omitempty"`
	VisualTags    []string `json:"visualTags"`
	AudioTags     []string `json:"audioTags"`
	AudioChannels []string `json:"audioChannels"`
	Languages     []string `json:"languages"`
	SeasonPack    bool     `json:"seasonPack"`
	Encode        string   `json:"encode,omitempty"`
}

type Service struct {
	ID     string `json:"id"`
	Cached bool   `json:"cached"`
}

type AddonSubtitle struct {
	ID          string `json:"id"`
	URL         string `json:"url"`
	LangCode    string `json:"lang_code"`
	SubID       int    `json:"sub_id"`
	FromTrusted bool   `json:"from_trusted"`
}
