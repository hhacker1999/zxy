package rest

import (
	"encoding/json"
	"fmt"
	"net/http"
)

type ApiResponse struct {
	Data       any
	StatusCode int
	Error      string
}

func (r *ApiResponse) SendResponse(w http.ResponseWriter) {
	if r.StatusCode == 0 {
		r.StatusCode = http.StatusOK
	}
	if r.Data == nil {
		w.WriteHeader(r.StatusCode)
		if len(r.Error) != 0 {
			w.Header().Set("Content-Type", "application/text")
			marshalledError, _ := json.Marshal(map[string]string{
				"error": r.Error,
			})
			_, err := w.Write(marshalledError)
			if err != nil {
				fmt.Println("Error writing error to response writer ", err)
			}
		}
		return
	}

	var err error
	bytes, ok := r.Data.([]byte)
	if !ok {
		bytes, err = json.Marshal(r.Data)
		if err != nil {
			fmt.Println("Error marhsalling data ", err)
			w.WriteHeader(http.StatusInternalServerError)
			marshalledError, _ := json.Marshal(map[string]string{
				"error": "Internal server error",
			})
			w.Header().Set("Content-Type", "application/text")
			_, err := w.Write(marshalledError)
			if err == nil {
				fmt.Println("Error writing error to response writer ", err)
			}
			return
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(r.StatusCode)
	_, err = w.Write(bytes)
	if err != nil {
		fmt.Println("Error writing data to response writer ", err)
	}
}
