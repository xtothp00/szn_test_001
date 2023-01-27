package main

import (
	"fmt"
	"os"
	"sort"
	"math/rand"
	"net/http"
	"github.com/gorilla/handlers"
	"github.com/namsral/flag"
)

var (
	listen_on    = flag.String("listen-on", "0.0.0.0:8090", "Address to bind to")
	secret_token = flag.String("secret_token", "", "Token to authorize requests")
)

func Hello(w http.ResponseWriter, req *http.Request) {
	if req.Header.Get("Authorization") != "Bearer "+*secret_token {
		w.WriteHeader(http.StatusForbidden)
		return
	}
	fmt.Fprintf(w, `
	<!doctype html>
	<html>
	<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	</head>
	<body>
	`)
	hostname, _ := os.Hostname()
	fmt.Fprintf(w, "<h1>%s</h1>", hostname)
	fmt.Fprintf(w, "<dl>")

	keys := make([]string, 0, len(req.Header))
	for k := range req.Header {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	for _, name := range keys {
		for _, h := range req.Header[name] {
			fmt.Fprintf(w, "<dt>%v</dt><dd>%v</dd>\n", name, h)
		}
	}

	fmt.Fprintf(w, `
	</dl>
	</body>
	</html>
	`)
}

func main() {
	flag.Parse()

	if *secret_token == "" {
		*secret_token = fmt.Sprintf("changeme:%d", rand.Int())
	}

	http.HandleFunc("/api/hello", Hello)

	fmt.Fprintf(os.Stderr, "Serving on %s protected with bearer token %s\n", *listen_on, *secret_token)
	http.ListenAndServe(*listen_on, handlers.LoggingHandler(os.Stdout, http.DefaultServeMux))
}
