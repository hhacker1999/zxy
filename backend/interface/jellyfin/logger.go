package jellyfin

import (
	"fmt"
	"net/http"
	"strings"
	"time"
)

const logPrefix = "[jellyfin]"

func jfLog(format string, args ...any) {
	fmt.Printf("%s %s\n", logPrefix, fmt.Sprintf(format, args...))
}

func jfLogRequest(r *http.Request, handler string) {
	jfLog(
		"request handler=%s method=%s path=%s query=%s remote=%s",
		handler,
		r.Method,
		r.URL.Path,
		r.URL.RawQuery,
		r.RemoteAddr,
	)
}

func jfLogAuthHeaders(r *http.Request) {
	jfLog(
		"auth-headers Authorization=%q X-Emby-Authorization=%q X-Emby-Token=%q ApiKey=%q",
		truncateForLog(r.Header.Get("Authorization"), 120),
		truncateForLog(r.Header.Get("X-Emby-Authorization"), 120),
		truncateForLog(r.Header.Get("X-Emby-Token"), 32),
		truncateForLog(r.URL.Query().Get("ApiKey"), 32),
	)
}

func jfLogResponse(handler string, status int, detail string) {
	if detail == "" {
		jfLog("response handler=%s status=%d", handler, status)
		return
	}
	jfLog("response handler=%s status=%d detail=%s", handler, status, detail)
}

func jfLogError(handler string, step string, err error) {
	if err == nil {
		jfLog("error handler=%s step=%s err=nil", handler, step)
		return
	}
	jfLog("error handler=%s step=%s err=%v", handler, step, err)
}

func truncateForLog(v string, max int) string {
	v = strings.TrimSpace(v)
	if v == "" {
		return "<empty>"
	}
	if len(v) <= max {
		return v
	}
	return v[:max] + "..."
}

func (s *Server) wrap(name string, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		jfLogRequest(r, name)
		if strings.Contains(name, "Auth") ||
			strings.Contains(name, "Login") ||
			strings.Contains(name, "Users/Me") ||
			strings.Contains(name, "Playback") ||
			strings.Contains(name, "stream") {
			jfLogAuthHeaders(r)
		}
		next(w, r)
		jfLog("done handler=%s elapsed=%s", name, time.Since(start))
	}
}

func (s *Server) wrapAuth(name string, next http.HandlerFunc) http.HandlerFunc {
	return s.wrap(name, s.authRequired(next))
}
