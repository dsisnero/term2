package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"charm.land/lipgloss/v2"
)

func main() {
	outPath := flag.String("out", "", "output golden file path")
	width := flag.Int("width", 80, "window width")
	height := flag.Int("height", 24, "window height")
	_ = width
	_ = height
	flag.Parse()

	if *outPath == "" {
		fmt.Fprintln(os.Stderr, "missing -out")
		os.Exit(2)
	}

	fancy := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#6b50ff")).
		Render("Howdy!")

	output := "This will produce the wrong colors on Apple Terminal :)\n\n" +
		fancy +
		"\n\n" +
		"Press any key to exit."

	if err := os.MkdirAll(filepath.Dir(*outPath), 0o755); err != nil {
		panic(err)
	}
	if err := os.WriteFile(*outPath, []byte(output), 0o644); err != nil {
		panic(err)
	}
}
