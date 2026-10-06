#!/bin/bash
# Spusti SUnit testy nad vyvojovym image (bez ulozeni). Argumenty: nazvy balicku (vychozi OpenPonk-Extras-Tests).
DIR="$(cd "$(dirname "$0")/.." && pwd)"
export OPENPONK_MCP_PORT="${OPENPONK_MCP_TEST_PORT:-47998}"  # headless instance nesmi obsadit port GUI (47100)
PKGS="${*:-OpenPonk-Extras-Tests}"
LIST=$(printf "'%s' " $PKGS)
"$DIR/build/Pharo.app/Contents/MacOS/Pharo" --headless "$DIR/build/image/openponk-plugins.image" eval "
| result s classes |
classes := (#( $LIST ) flatCollect: [ :p | (self packageOrganizer packageNamed: p) definedClasses select: [ :c | c isTestCase and: [ c isAbstract not ] ] ]).
result := (TestSuite new addTests: (classes flatCollect: [ :c | c suite tests ]); yourself) run.
s := WriteStream on: String new.
s nextPutAll: result printString; cr.
(result failures, result errors) do: [ :t | s nextPutAll: 'FAIL: ', t printString; cr ].
s contents
"
