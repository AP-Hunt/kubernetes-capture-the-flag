package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"log"
	"net/http"
)

const hmacKey = "whJ4vK9pLm2xR7nBfQ3dYs8tAe6gCu0i"

func main() {
	http.HandleFunc("/healthz", handleHealthz)
	http.HandleFunc("/metrics", handleMetrics)
	http.HandleFunc("/callback", handleCallback)
	log.Println("payment-callbacks-receiver listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func handleHealthz(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintln(w, `{"status":"ok"}`)
}

func handleMetrics(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain")
	fmt.Fprintln(w, "# HELP payment_callbacks_received_total Total payment callbacks received.")
	fmt.Fprintln(w, "# TYPE payment_callbacks_received_total counter")
	fmt.Fprintln(w, "payment_callbacks_received_total 0")
	fmt.Fprintln(w, "# HELP payment_callbacks_hmac_failures_total Total HMAC validation failures.")
	fmt.Fprintln(w, "# TYPE payment_callbacks_hmac_failures_total counter")
	fmt.Fprintln(w, "payment_callbacks_hmac_failures_total 0")
}

func handleCallback(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	sig := r.Header.Get("X-Signature")
	if sig == "" {
		http.Error(w, "missing signature", http.StatusForbidden)
		return
	}
	mac := hmac.New(sha256.New, []byte(hmacKey))
	mac.Write(body)
	expected := hex.EncodeToString(mac.Sum(nil))
	if !hmac.Equal([]byte(sig), []byte(expected)) {
		http.Error(w, "invalid signature", http.StatusForbidden)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintln(w, `{"status":"accepted"}`)
}
