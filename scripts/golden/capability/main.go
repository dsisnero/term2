package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"charm.land/bubbles/v2/textinput"
	"charm.land/lipgloss/v2"
)

type model struct {
	input textinput.Model
	width int
}

func main() {
	outPath := flag.String("out", "", "output golden file path")
	width := flag.Int("width", 80, "window width")
	height := flag.Int("height", 24, "window height")
	_ = height
	flag.Parse()

	if *outPath == "" {
		fmt.Fprintln(os.Stderr, "missing -out")
		os.Exit(2)
	}

	m := model{}
	m.input = textinput.New()
	m.input.Placeholder = "Enter capability name to request"
	m.input.Focus()
	m.width = *width

	w := min(m.width, 60)
	instructions := lipgloss.NewStyle().
		Width(w).
		Render("Query for terminal capabilities. You can enter things like 'TN', 'RGB', 'cols', and so on. This will not work in all terminals and multiplexers.")

	output := "\n" + instructions + "\n\n" +
		m.input.View() +
		"\n\nPress enter to request capability, or ctrl+c to quit."

	if err := os.MkdirAll(filepath.Dir(*outPath), 0o755); err != nil {
		panic(err)
	}
	if err := os.WriteFile(*outPath, []byte(output), 0o644); err != nil {
		panic(err)
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
