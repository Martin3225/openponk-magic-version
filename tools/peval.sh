#!/bin/bash
# Spusti Smalltalk kod ze stdin headless nad vyvojovym image (bez ulozeni) a vypise vysledek.
# Pouziti: tools/peval.sh [cesta/k/image] < kod.st
DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMG="${1:-$DIR/build/image/openponk-plugins.image}"
CODE="$(cat)"
"$DIR/build/Pharo.app/Contents/MacOS/Pharo" --headless "$IMG" eval "$CODE" 2>&1
