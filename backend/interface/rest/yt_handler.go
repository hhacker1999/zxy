package rest

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var pathExpireRegex = regexp.MustCompile(`/expire/(\d+)/`)

func extractURL(videoID string) (string, error) {
	videoURL := "https://www.youtube.com/watch?v=" + videoID

	cmd := exec.Command(
		"yt-dlp",
		"-f", "best[ext=mp4]/best",
		"-g",
		videoURL,
	)

	out, err := cmd.Output()
	if err != nil {
		return "", err
	}

	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	if len(lines) == 0 {
		return "", fmt.Errorf("no stream url found")
	}

	return lines[0], nil
}

func (i *RestInterface) handleYtStream(w http.ResponseWriter, r *http.Request) {
	videoID := r.URL.Query().Get("id")
	if videoID == "" {
		http.Error(w, "missing id", http.StatusBadRequest)
		return
	}

	var streamURL string
	var err error
	streamURL, err = i.ytRedisDb.Get(context.Background(), videoID).Result()
	if err != nil {
		fmt.Println("YT link not found in cache")
	}

	if len(streamURL) == 0 {
		streamURL, err = extractURL(videoID)
		if err != nil {
			fmt.Println("Error extracting url from id", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		u, err := url.Parse(streamURL)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Query param style:
		// ?expire=1778882859
		var expiry int64
		if exp := u.Query().Get("expire"); exp != "" {
			expiry, _ = strconv.ParseInt(exp, 10, 64)
		} else {
			// Path style:
			// /expire/1778882859/
			matches := pathExpireRegex.FindStringSubmatch(u.Path)
			if len(matches) == 2 {
				expiry, _ = strconv.ParseInt(matches[1], 10, 64)
			}
		}

		if expiry != 0 {
			ttl := time.Unix(expiry, 0).Add(-5 * time.Minute).Sub(time.Now())
			_, err = i.ytRedisDb.Set(context.Background(), videoID, streamURL, ttl).Result()
			if err != nil {
				fmt.Println("Error storing yt stream url in cache", err)
			}
		}

	}

	req, err := http.NewRequest("GET", streamURL, nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if rangeHeader := r.Header.Get("Range"); rangeHeader != "" {
		req.Header.Set("Range", rangeHeader)
	}

	req.Header.Set("User-Agent", "Mozilla/5.0")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	for k, v := range resp.Header {
		for _, vv := range v {
			w.Header().Add(k, vv)
		}
	}

	w.WriteHeader(resp.StatusCode)

	_, err = io.Copy(w, resp.Body)
	if err != nil {
		log.Println(err)
	}
}
