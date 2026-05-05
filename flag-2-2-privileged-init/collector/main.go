package main

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

func main() {
	go func() {
		for {
			log.Println("collecting node metrics...")
			time.Sleep(30 * time.Second)
		}
	}()

	http.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "# HELP node_collector_up Whether the node collector is running.")
		fmt.Fprintln(w, "# TYPE node_collector_up gauge")
		fmt.Fprintln(w, "node_collector_up 1")
	})

	log.Println("serving metrics on :9100")
	log.Fatal(http.ListenAndServe(":9100", nil))
}
