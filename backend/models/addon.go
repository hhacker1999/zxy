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

type BehaviorHints struct {
	BingeGroup string `json:"bingeGroup"`
	VideoSize  int64  `json:"videoSize"`
	Filename   string `json:"filename"`
}
