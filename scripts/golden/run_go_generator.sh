#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GEN_PATH=""
OUT_PATH=""
WIDTH=80
HEIGHT=24
DIR="temp"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -gen)
      GEN_PATH="$2"
      shift 2
      ;;
    -out)
      OUT_PATH="$2"
      shift 2
      ;;
    -width)
      WIDTH="$2"
      shift 2
      ;;
    -height)
      HEIGHT="$2"
      shift 2
      ;;
    -dir)
      DIR="$2"
      shift 2
      ;;
    --)
      shift
      EXTRA_ARGS=("$@")
      break
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$GEN_PATH" ]]; then
  echo "missing -gen <path>" >&2
  exit 2
fi
if [[ -z "$OUT_PATH" ]]; then
  echo "missing -out <path>" >&2
  exit 2
fi

BUBBLES_DIR="${BUBBLES_DIR:-$ROOT_DIR/../vendor/bubbles}"
BUBBLETEA_DIR="${BUBBLETEA_DIR:-$ROOT_DIR/../vendor/bubbletea}"
LIPGLOSS_DIR="${LIPGLOSS_DIR:-$ROOT_DIR/../vendor/lipgloss}"

if [[ ! -d "$BUBBLES_DIR" ]]; then
  echo "BUBBLES_DIR not found: $BUBBLES_DIR" >&2
  exit 1
fi
if [[ ! -d "$BUBBLETEA_DIR" ]]; then
  echo "BUBBLETEA_DIR not found: $BUBBLETEA_DIR" >&2
  exit 1
fi
if [[ ! -d "$LIPGLOSS_DIR" ]]; then
  echo "LIPGLOSS_DIR not found: $LIPGLOSS_DIR" >&2
  exit 1
fi

CACHE_ROOT="${CACHE_ROOT:-$ROOT_DIR/../temp/go-golden}"
mkdir -p "$CACHE_ROOT"
WORK_DIR="$(mktemp -d "$CACHE_ROOT/run.XXXXXX")"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

GOCACHE="${GOCACHE:-$CACHE_ROOT/go-build-cache}"
GOMODCACHE="${GOMODCACHE:-$CACHE_ROOT/go-mod-cache}"
mkdir -p "$GOCACHE" "$GOMODCACHE"

# Some local setups export a stale GOROOT (e.g. older mise install path),
# which causes "compile: version ... does not match go tool version ..." errors.
# Let `go` resolve the matching toolchain root itself.
unset GOROOT

cat > "$WORK_DIR/go.mod" <<EOF
module term2-golden

go 1.24.2

require (
  charm.land/bubbles/v2 v2.0.0
  charm.land/bubbletea/v2 v2.0.0
  charm.land/lipgloss/v2 v2.0.0
)

replace charm.land/bubbles/v2 => $BUBBLES_DIR
replace charm.land/bubbletea/v2 => $BUBBLETEA_DIR
replace charm.land/lipgloss/v2 => $LIPGLOSS_DIR
EOF

cp "$GEN_PATH" "$WORK_DIR/main.go"

(
  cd "$WORK_DIR"
  GOWORK=off GOTOOLCHAIN=local GOCACHE="$GOCACHE" GOMODCACHE="$GOMODCACHE" go mod tidy
flags_output="$(
  GOWORK=off GOTOOLCHAIN=local GOCACHE="$GOCACHE" GOMODCACHE="$GOMODCACHE" go run . -h 2>&1 || true
)"

args=(-out "$OUT_PATH")
if echo "$flags_output" | grep -q -- "-width"; then
  args+=(-width "$WIDTH")
fi
if echo "$flags_output" | grep -q -- "-height"; then
  args+=(-height "$HEIGHT")
fi
if echo "$flags_output" | grep -q -- "-dir"; then
  if [[ "$DIR" != "temp" ]]; then
    args+=(-dir "$DIR")
  fi
fi

GOWORK=off GOTOOLCHAIN=local GOCACHE="$GOCACHE" GOMODCACHE="$GOMODCACHE" go run . "${args[@]}" "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"
)

echo "Wrote golden file to $OUT_PATH"
