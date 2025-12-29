package rest

import (
	"fmt"
	"io"
	"net/http"
)

func (i *RestInterface) handleSignup(w http.ResponseWriter, r *http.Request) {
	defer func() {
		w.WriteHeader(http.StatusOK)
	}()
	bodyBytes, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Println("Error reading request body")
		return
	}
	fmt.Println(string(bodyBytes))
}
