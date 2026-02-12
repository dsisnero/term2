package main

import (
	"bytes"
	"flag"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

var update = flag.Bool("update", false, "update golden files")

func TestMain(m *testing.M) {
	flag.Parse()
	os.Exit(m.Run())
}

func TestCanvas(t *testing.T) {
	// Determine directory of this test
	dir, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}

	// Create command: go run main.go
	cmd := exec.Command("go", "run", ".")
	cmd.Dir = dir
	// Set environment for deterministic color output
	cmd.Env = append(os.Environ(),
		"TERM=dumb",
		"NO_COLOR=1",
	)

	// Capture stdout and stderr
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	// Run command
	if err := cmd.Run(); err != nil {
		t.Fatalf("command failed: %v\nstderr: %s", err, stderr.String())
	}

	output := stdout.Bytes()

	// Golden file path
	golden := filepath.Join("testdata", t.Name()+".golden")

	// Update golden file if -update flag is provided
	if *update {
		os.MkdirAll(filepath.Dir(golden), 0755)
		if err := os.WriteFile(golden, output, 0644); err != nil {
			t.Fatal(err)
		}
		return
	}

	// Read expected output
	expected, err := os.ReadFile(golden)
	if err != nil {
		t.Fatalf("failed to read golden file %s: %v", golden, err)
	}

	// Compare
	if !bytes.Equal(output, expected) {
		t.Errorf("output does not match golden file %s", golden)
		t.Logf("expected length %d, got %d", len(expected), len(output))
		// Show first diff position
		minLen := len(expected)
		if len(output) < minLen {
			minLen = len(output)
		}
		for i := 0; i < minLen; i++ {
			if expected[i] != output[i] {
				t.Logf("first diff at byte %d: expected %x, got %x", i, expected[i], output[i])
				break
			}
		}
	}
}
