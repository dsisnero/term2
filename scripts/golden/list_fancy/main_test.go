package main

import (
	"flag"
	"os"
	"path/filepath"
	"testing"
)

func TestListFancyGolden(t *testing.T) {
	// Determine path to golden file relative to repo root
	repoRoot := os.Getenv("REPO_ROOT")
	if repoRoot == "" {
		// Assume we're running from repo root
		repoRoot = "."
	}
	goldenPath := filepath.Join(repoRoot, "spec", "testdata", "ListFancy", "default.golden")

	// Read golden file
	expected, err := os.ReadFile(goldenPath)
	if err != nil {
		t.Fatalf("Failed to read golden file %s: %v", goldenPath, err)
	}

	// Generate output using renderListFancy with same dimensions as generator script (80x24)
	output := renderListFancy(80, 24)

	if string(expected) != output {
		t.Errorf("Output does not match golden file %s", goldenPath)
		t.Logf("Expected length %d, got length %d", len(expected), len(output))
		// Optionally, write diff
	}
}

func TestMain(m *testing.M) {
	// Ensure deterministic random seed
	flag.Parse()
	os.Exit(m.Run())
}
