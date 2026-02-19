package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"charm.land/bubbles/v2/textinput"
)

func main() {
	outPath := flag.String("out", "", "output golden file path")
	flag.Parse()

	if *outPath == "" {
		fmt.Fprintln(os.Stderr, "missing -out")
		os.Exit(2)
	}

	ti := textinput.New()
	ti.Focus()
	ti.CharLimit = 156
	ti.SetWidth(20)
	ti.SetVirtualCursor(false)

	output := ti.View() + "\n\nPress ctrl+c to quit, enter to write the sequence to terminal"

	if err := os.MkdirAll(filepath.Dir(*outPath), 0o755); err != nil {
		panic(err)
	}
	if err := os.WriteFile(*outPath, []byte(output), 0o644); err != nil {
		panic(err)
	}
}
