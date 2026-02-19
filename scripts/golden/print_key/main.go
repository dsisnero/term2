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

	output := "Press any key to see its details printed to the terminal. Press 'ctrl+c' to quit."

	if err := os.MkdirAll(filepath.Dir(*outPath), 0o755); err != nil {
		panic(err)
	}
	if err := os.WriteFile(*outPath, []byte(output), 0o644); err != nil {
		panic(err)
	}
}
