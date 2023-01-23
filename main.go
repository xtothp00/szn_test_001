package main

import (
	"github.com/xtothp00/szn_test_001/cmd/server"
)

func main() {
	flag.Parse()

	if *secret_token == "" {
		*secret_token = fmt.Sprintf("changeme:%d", rand.Int())
	}

	http.HandleFunc("/api/hello", server.Hello)

	fmt.Fprintf(os.Stderr, "Serving on %s protected with bearer token %s\n", *listen_on, *secret_token)
	http.ListenAndServe(*listen_on, handlers.LoggingHandler(os.Stdout, http.DefaultServeMux))
}
