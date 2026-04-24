package models

const REAL_DEBRID = "realdebrid"
const TORBOX = "torbox"
const WEBSTREAMR = "webstreamr"
const OPEN_SUBTITLES_V3 = "opensubtitles-v3-plus"
const HDHUB = "hdhub"

var AvailableServiesAndPresets = []ProfileService{
	{
		Name:      "Real Debrid",
		Id:        REAL_DEBRID,
		InputType: "string",
	},
	{
		Name:      "Torbox",
		Id:        TORBOX,
		InputType: "string",
	},
	{
		Name:      "WebStreamr",
		Id:        WEBSTREAMR,
		InputType: "bool",
	},
	{
		Name:      "HDHub",
		Id:        HDHUB,
		InputType: "bool",
	},
}

var AvailablePresets = []string{
	WEBSTREAMR,
	HDHUB,
}
