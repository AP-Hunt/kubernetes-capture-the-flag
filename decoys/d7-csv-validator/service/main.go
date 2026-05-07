package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
)

type result struct {
	Rows    int      `json:"rows"`
	Columns int      `json:"columns"`
	Headers []string `json:"headers"`
	Errors  []string `json:"errors"`
}

func main() {
	http.HandleFunc("/healthz", handleHealthz)
	http.HandleFunc("/validate", handleValidate)
	log.Println("csv-validator listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func handleHealthz(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintln(w, `{"status":"ok"}`)
}

func handleValidate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	file, _, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "missing file field in multipart form", http.StatusBadRequest)
		return
	}
	defer file.Close()

	reader := csv.NewReader(file)
	res := result{}

	headers, err := reader.Read()
	if err != nil {
		res.Errors = append(res.Errors, "unable to read CSV headers: "+err.Error())
		writeJSON(w, res)
		return
	}
	res.Headers = headers
	res.Columns = len(headers)

	row := 1
	for {
		_, err := reader.Read()
		if err == io.EOF {
			break
		}
		row++
		if err != nil {
			res.Errors = append(res.Errors, fmt.Sprintf("parse error at row %d: %s", row, err.Error()))
		}
	}
	res.Rows = row

	writeJSON(w, res)
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(v)
}
