#!/bin/bash
# Spusti vsechny testy z balicku OpenPonk-* (krome OpenPonk-Extras*) nad kopii zadaneho image a vypise selhani.
# Pouziti: tools/regress.sh <adresar-s-image> <vystupni-soubor>
DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$1"; OUT="$2"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/opregress.XXXX")"
cp "$SRC/openponk-plugins.image" "$SRC/openponk-plugins.changes" "$TMP/"
ln -s "$DIR/build/image/Pharo14.0-64bit-4da0477.sources" "$TMP/" 2>/dev/null
"$DIR/build/Pharo.app/Contents/MacOS/Pharo" --headless "$TMP/openponk-plugins.image" eval "
| classes result s |
classes := ((self packageOrganizer packages select: [ :p | (p name beginsWith: 'OpenPonk') and: [ (p name beginsWith: 'OpenPonk-Extras') not ] ])
  flatCollect: [ :p | p definedClasses select: [ :c | c isTestCase and: [ c isAbstract not ] ] ]) asSet asArray sort: [ :a :b | a name <= b name ].
result := (TestSuite new addTests: (classes flatCollect: [ :c | c suite tests ]); yourself) run.
s := WriteStream on: String new.
s nextPutAll: result printString; cr.
((result failures, result errors) collect: [ :t | t printString ]) asSortedCollection do: [ :t | s nextPutAll: 'FAIL: ', t; cr ].
s contents
" > "$OUT" 2>&1
rm -rf "$TMP"
