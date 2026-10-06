#!/bin/bash
# Spusti Smalltalk kod ze stdin headless nad vyvojovym image (bez ulozeni) a vypise vysledek.
# Pouziti: tools/peval.sh [cesta/k/image] < kod.st
DIR="$(cd "$(dirname "$0")/.." && pwd)"
export OPENPONK_MCP_PORT="${OPENPONK_MCP_TEST_PORT:-47998}"  # headless instance nesmi obsadit port GUI (47100)
IMG="${1:-$DIR/build/image/openponk-plugins.image}"
CODE="$(cat)"
"$DIR/build/Pharo.app/Contents/MacOS/Pharo" --headless "$IMG" eval "$CODE" 2>&1
