package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

var firePalette = []int{0, 233, 234, 52, 53, 88, 89, 94, 95, 96, 130, 131, 132, 133, 172, 214, 215, 220, 220, 221, 3, 226, 227, 230, 231, 7}
var ramp = []rune{' ', '.', ':', '-', '=', '+', '*', '#', '%', '@'}

func main() {
	outPath := flag.String("out", "", "output golden file path")
	width := flag.Int("width", 20, "window width")
	height := flag.Int("height", 8, "window height")
	ticks := flag.Int("ticks", 2, "fire simulation ticks before render")
	flag.Parse()

	if *outPath == "" {
		fmt.Fprintln(os.Stderr, "missing -out")
		os.Exit(2)
	}

	renderHeight := *height * 2
	screenBuf := make([]int, *width*renderHeight)
	for i := range *width {
		screenBuf[(renderHeight-1)**width+i] = len(firePalette) - 1
	}

	for frame := range *ticks {
		spreadFire(screenBuf, *width, renderHeight, frame)
	}

	output := render(screenBuf, *width, renderHeight)

	if err := os.MkdirAll(filepath.Dir(*outPath), 0o755); err != nil {
		panic(err)
	}
	if err := os.WriteFile(*outPath, []byte(output), 0o644); err != nil {
		panic(err)
	}
}

func spreadFire(screenBuf []int, width int, height int, frame int) {
	for x := range width {
		for y := range height {
			spreadPixel(screenBuf, width, y*width+x, frame)
		}
	}
}

func spreadPixel(screenBuf []int, width int, idx int, frame int) {
	if idx < width {
		return
	}

	pixel := screenBuf[idx]
	if pixel == 0 {
		screenBuf[idx-width] = 0
		return
	}

	rnd := pseudoRand3(idx, frame)
	dst := idx - rnd + 1
	if dst-width >= 0 && dst-width < len(screenBuf) {
		decay := rnd & 1
		next := pixel - decay
		if next < 0 {
			next = 0
		}
		screenBuf[dst-width] = next
	}
}

func pseudoRand3(idx int, frame int) int {
	seed := int64(idx)*1_103_515_245 + int64(frame)*12_345 + 9_876_543
	return int((seed & 0x7fff_ffff) % 3)
}

func render(screenBuf []int, width int, height int) string {
	var s strings.Builder
	for y := 0; y < height-2; y += 2 {
		for x := range width {
			hi := screenBuf[y*width+x]
			lo := screenBuf[(y+1)*width+x]
			avg := (hi + lo) / 2
			rampIdx := (avg * (len(ramp) - 1)) / (len(firePalette) - 1)
			s.WriteRune(ramp[rampIdx])
		}
		if y < height-2 {
			s.WriteByte('\n')
		}
	}
	s.WriteString("Press q or ctrl+c to quit. Elapsed: 0s")
	return s.String()
}
