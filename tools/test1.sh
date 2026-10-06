#!/bin/bash
# Spusti jeden test (Trida selektor) a vypise duvod selhani se zasobnikem.
DIR="$(cd "$(dirname "$0")/.." && pwd)"
"$DIR/build/Pharo.app/Contents/MacOS/Pharo" --headless "$DIR/build/image/openponk-plugins.image" eval "
| t s |
s := WriteStream on: String new.
t := (Smalltalk at: #$1) selector: #$2.
[ t setUp. [ t performTest. s nextPutAll: 'PASS' ] ensure: [ t tearDown ] ]
  on: Error, TestFailure do: [ :e |
    s nextPutAll: e class name, ': ', e messageText asString; cr.
    (e signalerContext stack first: 25) do: [ :c | s nextPutAll: '  ', c printString; cr ].
    [ t tearDown ] on: Error do: [ :e2 | ] ].
s contents
" 2>&1 | grep -v Deprecation
