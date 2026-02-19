#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_PATH="${OUT_PATH:-$ROOT_DIR/spec/testdata/ColorProfile/default.golden}"
WIDTH="${WIDTH:-80}"
HEIGHT="${HEIGHT:-24}"

"$ROOT_DIR/scripts/golden/run_go_generator.sh" \
  -gen "$ROOT_DIR/scripts/golden/colorprofile/main.go" \
  -out "$OUT_PATH" \
  -width "$WIDTH" \
  -height "$HEIGHT"
