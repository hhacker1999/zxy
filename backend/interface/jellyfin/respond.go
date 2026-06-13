package jellyfin

import (
	"encoding/json"
	"net/http"
)

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if payload == nil {
		return
	}
	data, err := json.Marshal(payload)
	if err != nil {
		return
	}
	_, _ = w.Write(data)
}

func writeEmpty(w http.ResponseWriter, status int) {
	w.WriteHeader(status)
}
