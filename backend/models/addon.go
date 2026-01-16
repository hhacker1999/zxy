package models

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
