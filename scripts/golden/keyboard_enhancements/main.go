package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	outPath := flag.String("out", "", "output golden file path")
	flag.Parse()

	if *outPath == "" {
		fmt.Fprintln(os.Stderr, "missing -out")
		os.Exit(2)
	}

	output := "Terminal supports key releases: false\n" +
		"Terminal supports key disambiguation: false\n" +
		"This demo logs key events. Press ctrl+c to quit.\n"

	if err := os.MkdirAll(filepath.Dir(*outPath), 0o755); err != nil {
		panic(err)
	}
	if err := os.WriteFile(*outPath, []byte(output), 0o644); err != nil {
		panic(err)
	}
}
