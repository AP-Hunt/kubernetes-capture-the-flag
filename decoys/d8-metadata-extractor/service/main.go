package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"
)

var allowlist = []string{
	"https://data.gov.uk/api/search-dataset?q=transport",
	"https://data.gov.uk/api/search-dataset?q=education",
	"https://data.gov.uk/api/search-dataset?q=health",
	"https://data.gov.uk/api/search-dataset?q=housing",
	"https://data.gov.uk/api/search-dataset?q=environment",
}

func main() {
	http.HandleFunc("/healthz", handleHealthz)
	http.HandleFunc("/datasets/", handleDataset)
	log.Println("metadata-extractor listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func handleHealthz(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintln(w, `{"status":"ok"}`)
}

func handleDataset(w http.ResponseWriter, r *http.Request) {
	// Parse /datasets/{id}/metadata
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/datasets/"), "/")
	if len(parts) != 2 || parts[1] != "metadata" {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}

	id, err := strconv.Atoi(parts[0])
	if err != nil || id < 0 || id >= len(allowlist) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]any{
			"error":     "dataset not found",
			"valid_ids": []int{0, 1, 2, 3, 4},
		})
		return
	}

	resp, err := http.Get(allowlist[id])
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadGateway)
		json.NewEncoder(w).Encode(map[string]string{"error": "upstream unavailable"})
		return
	}
	defer resp.Body.Close()

	w.Header().Set("Content-Type", resp.Header.Get("Content-Type"))
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}
