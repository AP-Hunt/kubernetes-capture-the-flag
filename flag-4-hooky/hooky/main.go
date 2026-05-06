package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
)

func main() {
	mode := flag.String("mode", "hooky", "hooky or admin")
	addr := flag.String("addr", ":8080", "listen address")
	flag.Parse()

	switch *mode {
	case "hooky":
		serveHooky(*addr)
	case "admin":
		serveAdmin(*addr)
	default:
		log.Fatalf("unknown mode: %s", *mode)
	}
}

// --- Hooky mode ---

type proxyRequest struct {
	URL    string `json:"url"`
	Method string `json:"method"`
	Body   string `json:"body"`
}

func serveHooky(addr string) {
	http.HandleFunc("/test", handleTest)
	http.HandleFunc("/debug/config", handleDebugConfig)
	http.HandleFunc("/healthz", handleHealthz)
	log.Printf("hooky listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}

func handleTest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req proxyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "bad request: "+err.Error(), http.StatusBadRequest)
		return
	}
	if req.URL == "" {
		http.Error(w, "url is required", http.StatusBadRequest)
		return
	}
	if req.Method == "" {
		req.Method = "GET"
	}

	proxyReq, err := http.NewRequest(req.Method, req.URL, strings.NewReader(req.Body))
	if err != nil {
		http.Error(w, "invalid request: "+err.Error(), http.StatusBadRequest)
		return
	}

	resp, err := http.DefaultClient.Do(proxyReq)
	if err != nil {
		http.Error(w, "proxy error: "+err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	w.Header().Set("Content-Type", resp.Header.Get("Content-Type"))
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func handleDebugConfig(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(os.Environ())
}

func handleHealthz(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintln(w, `{"status":"ok"}`)
}

// --- Admin mode ---

func serveAdmin(addr string) {
	adminResponse := os.Getenv("ADMIN_RESPONSE")
	if adminResponse == "" {
		adminResponse = "no response configured"
	}
	http.HandleFunc("/admin", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, adminResponse)
	})
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, `{"status":"ok"}`)
	})
	log.Printf("admin-api listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
