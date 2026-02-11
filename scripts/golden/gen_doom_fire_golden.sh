#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_PATH="${OUT_PATH:-$ROOT_DIR/spec/testdata/DoomFire/default.golden}"
WIDTH="${WIDTH:-20}"
HEIGHT="${HEIGHT:-8}"
TICKS="${TICKS:-2}"

mkdir -p "$(dirname "$OUT_PATH")"

env -u GOROOT go run "$ROOT_DIR/scripts/golden/doom_fire/main.go" \
  -out "$OUT_PATH" \
  -width "$WIDTH" \
  -height "$HEIGHT" \
  -ticks "$TICKS"

echo "Wrote golden file to $OUT_PATH"
