package rest

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"encoding/hex"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
	"zxy/models"
)

var ipRequestHeaders = []string{
	"X-Client-Ip",         // Amazon EC2 / Heroku / others
	"Cf-Connecting-Ip",    // Cloudflare
	"Do-Connecting-Ip",    // DigitalOcean
	"Fastly-Client-Ip",    // Fastly / Firebase
	"True-Client-Ip",      // Akamai / Cloudflare
	"X-Real-Ip",           // nginx
	"X-Cluster-Client-Ip", // Rackspace LB / Riverbed's Stingray
	"X-Forwarded",
	"X-Forwarded-For", // Load-balancers (AWS ELB) / proxies.
	"Forwarded-For",
	"Forwarded",
	"X-Appengine-User-Ip", // Google Cloud App Engine
	"Cf-Pseudo-IPv4",      // Cloudflare fallback
}

func (i *RestInterface) HandleGetStream(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)

	params := r.URL.Query()
	streamType := params.Get("type")
	if len(streamType) == 0 || (streamType != "movie" && streamType != "series") {
		response.Error = "Invalid stream type"
		response.StatusCode = http.StatusBadRequest
		return
	}
	id := params.Get("id")
	if len(id) == 0 {
		response.Error = "Invalid id"
		response.StatusCode = http.StatusBadRequest
		return
	}
	var data models.ZxyStreamsRes
	var err error

	userIp := GetRequestIP(r)
	fmt.Println("User IP found is ", userIp)

	if streamType == "series" {
		season := params.Get("season")
		if len(season) == 0 {
			response.Error = "Invalid season"
			response.StatusCode = http.StatusBadRequest
			return
		}
		seasonInt, errr := strconv.Atoi(season)
		if errr != nil {
			response.Error = "Invalid season"
			response.StatusCode = http.StatusBadRequest
			return
		}

		episode := params.Get("episode")
		if len(episode) == 0 {
			response.Error = "Invalid episode"
			response.StatusCode = http.StatusBadRequest
			return
		}
		episodeInt, errr := strconv.Atoi(episode)
		if errr != nil {
			response.Error = "Invalid episode"
			response.StatusCode = http.StatusBadRequest
			return
		}
		data, err = i.addonuc.GetSeriesStreamProfile(id, seasonInt, episodeInt, profileId, userIp)
	} else {
		data, err = i.addonuc.GetMovieStreamProfile(id, profileId, userIp)
	}

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = data
}

func (i *RestInterface) HandleGetStreamV2(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)

	params := r.URL.Query()
	streamType := params.Get("type")
	if len(streamType) == 0 || (streamType != "movie" && streamType != "series") {
		response.Error = "Invalid stream type"
		response.StatusCode = http.StatusBadRequest
		return
	}
	id := params.Get("id")
	if len(id) == 0 {
		response.Error = "Invalid id"
		response.StatusCode = http.StatusBadRequest
		return
	}
	subLang := params.Get("subtitle")
	var data models.ZxyStreamsRes
	var err error

	userIp := GetRequestIP(r)
	fmt.Println("User IP found is ", userIp)

	if streamType == "series" {
		season := params.Get("season")
		if len(season) == 0 {
			response.Error = "Invalid season"
			response.StatusCode = http.StatusBadRequest
			return
		}
		seasonInt, errr := strconv.Atoi(season)
		if errr != nil {
			response.Error = "Invalid season"
			response.StatusCode = http.StatusBadRequest
			return
		}

		episode := params.Get("episode")
		if len(episode) == 0 {
			response.Error = "Invalid episode"
			response.StatusCode = http.StatusBadRequest
			return
		}
		episodeInt, errr := strconv.Atoi(episode)
		if errr != nil {
			response.Error = "Invalid episode"
			response.StatusCode = http.StatusBadRequest
			return
		}
		data, err = i.addonuc.GetSeriesStreamZxy(
			id,
			seasonInt,
			episodeInt,
			userId,
			profileId,
			userIp,
			subLang,
		)
	} else {
		data, err = i.addonuc.GetMovieStreamZxy(id, userId, profileId, userIp, subLang)
	}

	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusInternalServerError
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = data
}

func (i *RestInterface) handleStream(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	initial := r.URL.Query().Get("internal")
	if len(initial) == 0 {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		res.SendResponse(w)
		return
	}

	i.mtx.RLock()
	defer i.mtx.RUnlock()
	url, ok := i.urlMap[initial]
	if ok {
		fmt.Println("Found url in cache", url.FinalUrl)
		http.Redirect(w, r, url.FinalUrl, http.StatusFound)
		return
	}

	plainText, err := i.resolveInternalURL(initial)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		res.SendResponse(w)
		return
	}

	fmt.Println("Initial decoded url", plainText)

	req, err := http.NewRequest("GET", plainText, nil)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		res.SendResponse(w)
		return
	}

	// req.Header.Set("Range", "bytes=0-0")

	resp, err := i.client.Do(req)
	if err != nil {
		var resErr *RedirectError
		if errors.As(err, &resErr) {
			finalURL := resErr.URL
			i.urlMap[initial] = RedirectUrlInfo{
				FinalUrl: finalURL,
				UrlTime:  time.Now(),
			}

			http.Redirect(w, r, finalURL, http.StatusFound)
			return
		}
		res.StatusCode = http.StatusBadGateway
		res.Error = "Source resolution failed"
		res.SendResponse(w)
		return
	}
	defer resp.Body.Close()

	res.StatusCode = http.StatusBadGateway
	res.Error = "Source resolution failed"
	res.SendResponse(w)
}

func (i *RestInterface) handleProxy(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	initial := r.URL.Query().Get("internal")
	if len(initial) == 0 {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		res.SendResponse(w)
		return
	}

	url, err := i.resolveInternalURL(initial)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		res.SendResponse(w)
		return
	}
	client := &http.Client{
		Timeout: 5 * time.Second,
	}

	resp, err := client.Head(url)
	if err != nil {
		res.StatusCode = http.StatusBadGateway
		res.Error = "Source resolution failed"
		res.SendResponse(w)
		return
	}
	defer resp.Body.Close()
	finalURL := resp.Request.URL.String()
	ctx := context.WithValue(r.Context(), "url", finalURL)

	i.proxy.ServeHTTP(w, r.WithContext(ctx))
}

func (i *RestInterface) resolveInternalURL(initial string) (string, error) {
	ciphertext, err := hex.DecodeString(initial)
	if err != nil {
		fmt.Println("Error decoding hex", err)
		return "", err
	}
	key, err := hex.DecodeString(i.encrKey)
	if err != nil {
		return "", err
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		fmt.Println("Error creating new cipher", err)
		return "", err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		fmt.Println("Error in new gcm", err)
		return "", err
	}

	nonceSize := gcm.NonceSize()
	nonce, actualCiphertext := ciphertext[:nonceSize], ciphertext[nonceSize:]

	plainText, err := gcm.Open(nil, nonce, actualCiphertext, nil)
	if err != nil {
		return "", err
	}
	return string(plainText), nil
}

func (i *RestInterface) ResolvePlayableStreamURL(internal string) (string, error) {
	if internal == "" {
		return "", fmt.Errorf("missing internal stream token")
	}

	i.mtx.RLock()
	cachedURL, ok := i.urlMap[internal]
	i.mtx.RUnlock()
	if ok {
		return cachedURL.FinalUrl, nil
	}

	plainText, err := i.resolveInternalURL(internal)
	if err != nil {
		return "", err
	}

	uri, err := url.Parse(plainText)
	if err == nil {
		splittedHost := strings.Split(uri.Host, ":")
		if len(splittedHost) == 1 {
			i.mtx.Lock()
			i.urlMap[internal] = RedirectUrlInfo{
				FinalUrl: plainText,
				UrlTime:  time.Now(),
			}
			i.mtx.Unlock()
			return plainText, nil
		}
	}

	req, err := http.NewRequest(http.MethodGet, plainText, nil)
	if err != nil {
		return "", err
	}

	resp, err := i.client.Do(req)
	if err != nil {
		var resErr *RedirectError
		if errors.As(err, &resErr) {
			i.mtx.Lock()
			i.urlMap[internal] = RedirectUrlInfo{
				FinalUrl: resErr.URL,
				UrlTime:  time.Now(),
			}
			i.mtx.Unlock()
			return resErr.URL, nil
		}
		return "", err
	}
	defer resp.Body.Close()

	finalURL := resp.Request.URL.String()
	i.mtx.Lock()
	i.urlMap[internal] = RedirectUrlInfo{
		FinalUrl: finalURL,
		UrlTime:  time.Now(),
	}
	i.mtx.Unlock()
	return finalURL, nil
}

func (i *RestInterface) handleFinalUrl(w http.ResponseWriter, r *http.Request) {
	var res ApiResponse
	defer res.SendResponse(w)
	tempUrl := r.URL.Query().Get("temp_url")
	if len(tempUrl) == 0 {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		return
	}

	fmt.Println("Url received", tempUrl)
	parsedUrl, err := url.Parse(tempUrl)
	if err != nil {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		return
	}

	initial := parsedUrl.Query().Get("internal")
	if len(initial) == 0 {
		res.StatusCode = http.StatusBadRequest
		res.Error = "Invalid url"
		return
	}

	fmt.Println("Initial found", initial)

	type Response struct {
		Url string `json:"url"`
	}

	finalURL, err := i.ResolvePlayableStreamURL(initial)
	if err != nil {
		res.StatusCode = http.StatusBadGateway
		res.Error = "Source resolution failed"
		return
	}

	res.StatusCode = http.StatusOK
	res.Data = Response{
		Url: finalURL,
	}
}

// NOTE: Logic stolen from [https://github.com/MunifTanjim/stremthru]
func GetRequestIP(r *http.Request) string {
	for _, header := range ipRequestHeaders {
		switch header {
		case "X-Forwarded-For":
			if host, ok := getClientIPFromXForwardedFor(r.Header.Get(header)); ok {
				return host
			}
		default:
			if host := r.Header.Get(header); isCorrectIP(host) {
				return host
			}
		}
	}

	if host, _, err := net.SplitHostPort(r.RemoteAddr); err == nil && isCorrectIP(host) {
		return host
	}

	return ""
}

func isCorrectIP(input string) bool {
	ip := net.ParseIP(input)
	return ip != nil && !ip.IsPrivate() && !ip.IsLoopback()
}

func getClientIPFromXForwardedFor(headers string) (string, bool) {
	if headers == "" {
		return "", false
	}
	for ip := range strings.SplitSeq(headers, ",") {
		if ip, _, _ := strings.Cut(strings.TrimSpace(ip), ":"); isCorrectIP(ip) {
			return ip, true
		}
	}
	return "", false
}
