package jellyfin

import "time"

type SystemInfo struct {
	ServerName                 string `json:"ServerName"`
	Version                    string `json:"Version"`
	Id                         string `json:"Id"`
	OperatingSystem            string `json:"OperatingSystem"`
	LocalAddress               string `json:"LocalAddress,omitempty"`
	StartupWizardCompleted     bool   `json:"StartupWizardCompleted"`
	HasPendingRestart          bool   `json:"HasPendingRestart"`
	TranscodingTempPath        string `json:"TranscodingTempPath,omitempty"`
	WebSocketPortNumber        int    `json:"WebSocketPortNumber,omitempty"`
	CompletedInstallations     []any  `json:"CompletedInstallations,omitempty"`
	CanSelfRestart             bool   `json:"CanSelfRestart"`
	CanLaunchWebBrowser        bool   `json:"CanLaunchWebBrowser"`
	HasUpdateAvailable         bool   `json:"HasUpdateAvailable"`
	HasConfigurablePlugins     bool   `json:"HasConfigurablePlugins"`
	HasConfigurableLiveTvTuners bool  `json:"HasConfigurableLiveTvTuners"`
	IsProductionEnvironment    bool   `json:"IsProductionEnvironment"`
	SupportsLibraryMonitor     bool   `json:"SupportsLibraryMonitor"`
	SupportsContentDownloading bool   `json:"SupportsContentDownloading"`
	SupportsMediaControl       bool   `json:"SupportsMediaControl"`
	SupportsPersistentIdentifier bool `json:"SupportsPersistentIdentifier"`
	SupportsSyncTranscoding     bool   `json:"SupportsSyncTranscoding"`
}

type PublicSystemInfo struct {
	ServerName             string `json:"ServerName"`
	Version                string `json:"Version"`
	ProductName            string `json:"ProductName"`
	Id                     string `json:"Id"`
	StartupWizardCompleted bool   `json:"StartupWizardCompleted"`
	LocalAddress           string `json:"LocalAddress,omitempty"`
	OperatingSystem        string `json:"OperatingSystem,omitempty"`
}

type AuthenticateRequest struct {
	Username string `json:"Username"`
	Pw       string `json:"Pw"`
	Password string `json:"Password"`
}

type AuthenticationResult struct {
	User         UserDto     `json:"User"`
	SessionInfo  SessionInfo `json:"SessionInfo"`
	AccessToken  string      `json:"AccessToken"`
	ServerId     string      `json:"ServerId"`
}

type SessionInfo struct {
	Id                       string              `json:"Id"`
	UserId                   string              `json:"UserId"`
	UserName                 string              `json:"UserName"`
	Client                   string              `json:"Client"`
	DeviceId                 string              `json:"DeviceId"`
	DeviceName               string              `json:"DeviceName"`
	ApplicationVersion       string              `json:"ApplicationVersion"`
	ServerId                 string              `json:"ServerId"`
	IsActive                 bool                `json:"IsActive"`
	LastActivityDate         string              `json:"LastActivityDate,omitempty"`
	LastPlaybackCheckIn      string              `json:"LastPlaybackCheckIn,omitempty"`
	RemoteEndPoint           string              `json:"RemoteEndPoint,omitempty"`
	PlayableMediaTypes       []string            `json:"PlayableMediaTypes"`
	SupportedCommands        []string            `json:"SupportedCommands"`
	SupportsMediaControl     bool                `json:"SupportsMediaControl"`
	SupportsRemoteControl    bool                `json:"SupportsRemoteControl"`
	HasCustomDeviceName      bool                `json:"HasCustomDeviceName"`
	AdditionalUsers          []any               `json:"AdditionalUsers"`
	NowPlayingQueue          []any               `json:"NowPlayingQueue"`
	NowPlayingQueueFullItems []any               `json:"NowPlayingQueueFullItems"`
	PlayState                sessionPlayState    `json:"PlayState"`
	Capabilities             sessionCapabilities `json:"Capabilities"`
}

type sessionPlayState struct {
	CanSeek       bool   `json:"CanSeek"`
	IsPaused      bool   `json:"IsPaused"`
	IsMuted       bool   `json:"IsMuted"`
	RepeatMode    string `json:"RepeatMode"`
	PlaybackOrder string `json:"PlaybackOrder"`
}

type sessionCapabilities struct {
	PlayableMediaTypes           []string `json:"PlayableMediaTypes"`
	SupportedCommands            []string `json:"SupportedCommands"`
	SupportsMediaControl         bool     `json:"SupportsMediaControl"`
	SupportsPersistentIdentifier bool     `json:"SupportsPersistentIdentifier"`
}

type UserConfiguration struct {
	PlayDefaultAudioTrack       bool     `json:"PlayDefaultAudioTrack"`
	SubtitleLanguagePreference  string   `json:"SubtitleLanguagePreference"`
	DisplayMissingEpisodes      bool     `json:"DisplayMissingEpisodes"`
	GroupedFolders              []any    `json:"GroupedFolders"`
	SubtitleMode                string   `json:"SubtitleMode"`
	DisplayCollectionsView      bool     `json:"DisplayCollectionsView"`
	EnableLocalPassword         bool     `json:"EnableLocalPassword"`
	OrderedViews                []any    `json:"OrderedViews"`
	LatestItemsExcludes         []any    `json:"LatestItemsExcludes"`
	MyMediaExcludes             []any    `json:"MyMediaExcludes"`
	HidePlayedInLatest          bool     `json:"HidePlayedInLatest"`
	RememberAudioSelections     bool     `json:"RememberAudioSelections"`
	RememberSubtitleSelections  bool     `json:"RememberSubtitleSelections"`
	EnableNextEpisodeAutoPlay   bool     `json:"EnableNextEpisodeAutoPlay"`
	CastReceiverId              string   `json:"CastReceiverId"`
}

type UserDto struct {
	Name                      string             `json:"Name"`
	Id                        string             `json:"Id"`
	ServerId                  string             `json:"ServerId"`
	HasPassword               bool               `json:"HasPassword"`
	HasConfiguredPassword     bool               `json:"HasConfiguredPassword"`
	HasConfiguredEasyPassword bool               `json:"HasConfiguredEasyPassword"`
	EnableAutoLogin           bool               `json:"EnableAutoLogin"`
	LastLoginDate             string             `json:"LastLoginDate,omitempty"`
	LastActivityDate          string             `json:"LastActivityDate,omitempty"`
	Configuration             *UserConfiguration `json:"Configuration,omitempty"`
	Policy                    *UserPolicy        `json:"Policy,omitempty"`
}

type UserPolicy struct {
	IsAdministrator                 bool `json:"IsAdministrator"`
	IsHidden                        bool `json:"IsHidden"`
	IsDisabled                      bool `json:"IsDisabled"`
	EnableUserPreferenceAccess      bool `json:"EnableUserPreferenceAccess"`
	EnableRemoteControlOfOtherUsers bool `json:"EnableRemoteControlOfOtherUsers"`
	EnableSharedDeviceControl       bool `json:"EnableSharedDeviceControl"`
	EnableRemoteAccess              bool `json:"EnableRemoteAccess"`
	EnableLiveTvManagement          bool `json:"EnableLiveTvManagement"`
	EnableLiveTvAccess              bool `json:"EnableLiveTvAccess"`
	EnableMediaPlayback             bool `json:"EnableMediaPlayback"`
	EnableAudioPlaybackTranscoding  bool `json:"EnableAudioPlaybackTranscoding"`
	EnableVideoPlaybackTranscoding  bool `json:"EnableVideoPlaybackTranscoding"`
	EnablePlaybackRemuxing          bool `json:"EnablePlaybackRemuxing"`
	EnableContentDeletion           bool `json:"EnableContentDeletion"`
	EnableContentDownloading        bool `json:"EnableContentDownloading"`
	EnableSyncTranscoding           bool `json:"EnableSyncTranscoding"`
	EnableMediaConversion           bool `json:"EnableMediaConversion"`
	EnableAllDevices                bool `json:"EnableAllDevices"`
	EnableAllChannels               bool `json:"EnableAllChannels"`
	EnableAllFolders                bool `json:"EnableAllFolders"`
	InvalidLoginAttemptCount        int  `json:"InvalidLoginAttemptCount"`
	LoginAttemptsBeforeLockout      int  `json:"LoginAttemptsBeforeLockout"`
	MaxActiveSessions               int  `json:"MaxActiveSessions"`
}

type NameGuidPair struct {
	Name string `json:"Name"`
	Id   string `json:"Id"`
}

type PersonInfo struct {
	Name            string `json:"Name"`
	Id              string `json:"Id"`
	Role            string `json:"Role,omitempty"`
	Type            string `json:"Type"`
	PrimaryImageTag string `json:"PrimaryImageTag,omitempty"`
}

type BaseItemDto struct {
	Name                     string              `json:"Name"`
	ServerId                 string              `json:"ServerId"`
	Id                       string              `json:"Id"`
	Etag                     string              `json:"Etag,omitempty"`
	Overview                 string              `json:"Overview,omitempty"`
	ProductionYear           int                 `json:"ProductionYear,omitempty"`
	PremiereDate             string              `json:"PremiereDate,omitempty"`
	CommunityRating          float64             `json:"CommunityRating,omitempty"`
	RunTimeTicks             int64               `json:"RunTimeTicks,omitempty"`
	OfficialRating           string              `json:"OfficialRating,omitempty"`
	Genres                   []string            `json:"Genres"`
	ProviderIds              map[string]string   `json:"ProviderIds,omitempty"`
	IsFolder                 bool                `json:"IsFolder"`
	ParentId                 string              `json:"ParentId,omitempty"`
	Type                     string              `json:"Type"`
	MediaType                string              `json:"MediaType,omitempty"`
	UserData                 *UserItemDataDto    `json:"UserData"`
	ChildCount               int                 `json:"ChildCount,omitempty"`
	RecursiveItemCount       int                 `json:"RecursiveItemCount,omitempty"`
	IndexNumber              int                 `json:"IndexNumber,omitempty"`
	ParentIndexNumber        int                 `json:"ParentIndexNumber,omitempty"`
	SeriesName               string              `json:"SeriesName,omitempty"`
	SeriesId                 string              `json:"SeriesId,omitempty"`
	SeasonId                 string              `json:"SeasonId,omitempty"`
	SeasonName               string              `json:"SeasonName,omitempty"`
	SeriesPrimaryImageTag    string              `json:"SeriesPrimaryImageTag,omitempty"`
	ImageTags                map[string]string   `json:"ImageTags,omitempty"`
	BackdropImageTags        []string            `json:"BackdropImageTags"`
	PrimaryImageAspectRatio  float64             `json:"PrimaryImageAspectRatio,omitempty"`
	CollectionType           string              `json:"CollectionType,omitempty"`
	DisplayPreferencesId     string              `json:"DisplayPreferencesId,omitempty"`
	LocationType             string              `json:"LocationType,omitempty"`
	MediaSources             []MediaSourceInfo   `json:"MediaSources,omitempty"`
	MediaStreams             []MediaStreamInfo   `json:"MediaStreams,omitempty"`
	MediaSourceCount         int                 `json:"MediaSourceCount,omitempty"`
	VideoType                string              `json:"VideoType,omitempty"`
	Status                   string              `json:"Status,omitempty"`
	EndDate                  string              `json:"EndDate,omitempty"`
	DateCreated              string              `json:"DateCreated,omitempty"`
	DateLastSaved            string              `json:"DateLastSaved,omitempty"`
	SortName                 string              `json:"SortName,omitempty"`
	OriginalTitle            string              `json:"OriginalTitle,omitempty"`
	Taglines                 []string            `json:"Taglines"`
	Tags                     []string            `json:"Tags"`
	ProductionLocations      []string            `json:"ProductionLocations,omitempty"`
	People                   []PersonInfo        `json:"People"`
	Studios                  []NameGuidPair      `json:"Studios"`
	CanDelete                bool                `json:"CanDelete"`
	CanDownload              bool                `json:"CanDownload"`
	Path                     string              `json:"Path,omitempty"`
	EnableMediaSourceDisplay bool                `json:"EnableMediaSourceDisplay,omitempty"`
	PlayAccess               string              `json:"PlayAccess,omitempty"`
	LockData                 bool                `json:"LockData,omitempty"`
	Container                string              `json:"Container,omitempty"`
	HasSubtitles             bool                `json:"HasSubtitles,omitempty"`
}

type UserItemDataDto struct {
	Key                    string  `json:"Key"`
	ItemId                 string  `json:"ItemId"`
	Played                 bool    `json:"Played"`
	PlaybackPositionTicks  int64   `json:"PlaybackPositionTicks"`
	PlayCount              int     `json:"PlayCount"`
	IsFavorite             bool    `json:"IsFavorite"`
	LastPlayedDate         string  `json:"LastPlayedDate,omitempty"`
	PlayedPercentage       float64 `json:"PlayedPercentage,omitempty"`
	UnplayedItemCount      int     `json:"UnplayedItemCount,omitempty"`
}

type QueryResult struct {
	Items            []BaseItemDto `json:"Items"`
	TotalRecordCount int           `json:"TotalRecordCount"`
	StartIndex       int           `json:"StartIndex"`
}

type MediaSourceInfo struct {
	Id                     string            `json:"Id"`
	Path                   string            `json:"Path,omitempty"`
	DirectStreamUrl        string            `json:"DirectStreamUrl,omitempty"`
	Protocol               string            `json:"Protocol"`
	Name                   string            `json:"Name,omitempty"`
	Container              string            `json:"Container,omitempty"`
	Size                   int64             `json:"Size,omitempty"`
	RunTimeTicks           int64             `json:"RunTimeTicks,omitempty"`
	SupportsDirectPlay     bool              `json:"SupportsDirectPlay"`
	SupportsDirectStream   bool              `json:"SupportsDirectStream"`
	SupportsTranscoding    bool              `json:"SupportsTranscoding"`
	SupportsProbing        bool              `json:"SupportsProbing"`
	IsRemote               bool              `json:"IsRemote"`
	RequiresOpening        bool              `json:"RequiresOpening"`
	RequiresClosing          bool              `json:"RequiresClosing"`
	RequiresLooping          bool              `json:"RequiresLooping"`
	ReadAtNativeFramerate    bool              `json:"ReadAtNativeFramerate"`
	TranscodingUrl           string            `json:"TranscodingUrl,omitempty"`
	TranscodingContainer     string            `json:"TranscodingContainer,omitempty"`
	TranscodingSubProtocol   string            `json:"TranscodingSubProtocol,omitempty"`
	Type                     string            `json:"Type"`
	MediaStreams             []MediaStreamInfo `json:"MediaStreams,omitempty"`
	RequiredHttpHeaders      map[string]string `json:"RequiredHttpHeaders,omitempty"`
}

type MediaStreamInfo struct {
	Codec     string `json:"Codec,omitempty"`
	Type      string `json:"Type"`
	Index     int    `json:"Index"`
	IsDefault bool   `json:"IsDefault"`
	Language  string `json:"Language,omitempty"`
}

type PlaybackInfoResponse struct {
	MediaSources  []MediaSourceInfo `json:"MediaSources"`
	PlaySessionId string            `json:"PlaySessionId"`
}

type PlaybackInfoRequest struct {
	UserId          string `json:"UserId,omitempty"`
	MaxStreamingBitrate int `json:"MaxStreamingBitrate,omitempty"`
	StartTimeTicks  int64  `json:"StartTimeTicks,omitempty"`
	AutoOpenLiveStream bool `json:"AutoOpenLiveStream,omitempty"`
}

type ProgressPayload struct {
	ItemId              string `json:"ItemId"`
	PositionTicks       int64  `json:"PositionTicks"`
	IsPaused            bool   `json:"IsPaused"`
	IsMuted             bool   `json:"IsMuted"`
	PlaySessionId       string `json:"PlaySessionId,omitempty"`
	MediaSourceId       string `json:"MediaSourceId,omitempty"`
}

type PlaybackStopInfo struct {
	ItemId        string `json:"ItemId"`
	PositionTicks int64  `json:"PositionTicks"`
	PlaySessionId string `json:"PlaySessionId,omitempty"`
}

type BrandingConfiguration struct {
	SplashscreenEnabled bool   `json:"SplashscreenEnabled"`
	LoginDisclaimer     string `json:"LoginDisclaimer"`
}

type EndpointInfo struct {
	IsLocal        bool   `json:"IsLocal"`
	IsInNetwork    bool   `json:"IsInNetwork"`
	ServerAddress  string `json:"ServerAddress"`
}

type DisplayPreferences struct {
	Id                 string            `json:"Id"`
	Client             string            `json:"Client"`
	UserId             string            `json:"UserId,omitempty"`
	CustomPrefs          map[string]string `json:"CustomPrefs"`
	SortBy               string            `json:"SortBy,omitempty"`
	SortOrder            string            `json:"SortOrder,omitempty"`
	RememberSorting      bool              `json:"RememberSorting,omitempty"`
	RememberIndexing     bool              `json:"RememberIndexing,omitempty"`
	PrimaryImageHeight   int               `json:"PrimaryImageHeight,omitempty"`
	PrimaryImageWidth    int               `json:"PrimaryImageWidth,omitempty"`
	ScrollDirection      string            `json:"ScrollDirection,omitempty"`
	ShowBackdrop         bool              `json:"ShowBackdrop,omitempty"`
	ShowSidebar          bool              `json:"ShowSidebar,omitempty"`
}

type cachedStream struct {
	URL       string
	FinalURL  string
	Container string
	Size      int64
	Name      string
	ExpiresAt time.Time
}

type VirtualFolderInfo struct {
	Name               string   `json:"Name"`
	Locations          []string `json:"Locations"`
	CollectionType     string   `json:"CollectionType"`
	ItemId             string   `json:"ItemId"`
	PrimaryImageItemId string   `json:"PrimaryImageItemId,omitempty"`
	RefreshStatus      string   `json:"RefreshStatus"`
}
