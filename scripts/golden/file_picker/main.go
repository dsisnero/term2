package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"charm.land/bubbles/v2/filepicker"
	tea "charm.land/bubbletea/v2"
)

func main() {
	outPath := flag.String("out", "", "output golden file path")
	width := flag.Int("width", 80, "window width")
	height := flag.Int("height", 24, "window height")
	dir := flag.String("dir", "temp", "current directory to render (\"temp\" for fixture)")
	flag.Parse()

	if *outPath == "" {
		fmt.Fprintln(os.Stderr, "missing -out")
		os.Exit(2)
	}

	tmpDir := ""
	if *dir == "temp" {
		var err error
		tmpDir, err = os.MkdirTemp("", "term2-filepicker")
		if err != nil {
			panic(err)
		}
		defer func() {
			_ = os.RemoveAll(tmpDir)
		}()

		alpha := filepath.Join(tmpDir, "alpha.cr")
		beta := filepath.Join(tmpDir, "beta.md")
		ignored := filepath.Join(tmpDir, "ignored.txt")
		if err := os.WriteFile(alpha, []byte(""), 0o644); err != nil {
			panic(err)
		}
		if err := os.Chmod(alpha, 0o644); err != nil {
			panic(err)
		}
		if err := os.WriteFile(beta, []byte(""), 0o644); err != nil {
			panic(err)
		}
		if err := os.Chmod(beta, 0o644); err != nil {
			panic(err)
		}
		if err := os.WriteFile(ignored, []byte(""), 0o644); err != nil {
			panic(err)
		}
		if err := os.Chmod(ignored, 0o644); err != nil {
			panic(err)
		}
	}

	fp := filepicker.New()
	if *dir == "temp" {
		fp.CurrentDirectory = tmpDir
	} else {
		fp.CurrentDirectory = *dir
	}
	fp.AllowedTypes = []string{".cr", ".md", ".yml", ".json"}
	fp.ShowHidden = false

	if cmd := fp.Init(); cmd != nil {
		msg := cmd()
		fp, _ = fp.Update(msg)
	}

	fp, _ = fp.Update(tea.WindowSizeMsg{Width: *width, Height: *height})

	var s strings.Builder
	s.WriteString("\n  Pick a file:")
	s.WriteString("\n\n")
	s.WriteString(fp.View())
	s.WriteString("\n")
	output := s.String()

	if err := os.MkdirAll(filepath.Dir(*outPath), 0o755); err != nil {
		panic(err)
	}
	if err := os.WriteFile(*outPath, []byte(output), 0o644); err != nil {
		panic(err)
	}
}
