#!/bin/bash
# Spusti vsechny testy jedne tridy postupne a u selhani vypise duvod.
DIR="$(cd "$(dirname "$0")/.." && pwd)"
"$DIR/build/Pharo.app/Contents/MacOS/Pharo" --headless "$DIR/build/image/openponk-plugins.image" eval "
| s |
s := WriteStream on: String new.
(#( $* ) flatCollect: [ :cn | (Smalltalk at: cn) testSelectors asSortedCollection collect: [ :x | cn -> x ] ]) do: [ :pair | | t sel | sel := pair value.
  t := (Smalltalk at: pair key) selector: sel.
  [ t setUp. [ t performTest. s nextPutAll: 'PASS ', sel; cr ] ensure: [ t tearDown ] ]
    on: Error, TestFailure do: [ :e |
      s nextPutAll: 'FAIL ', sel, ': ', e class name, ' ', e messageText asString; cr.
      (e signalerContext stack first: 6) do: [ :c | s nextPutAll: '    ', c printString; cr ].
      [ t tearDown ] on: Error do: [ :e2 | ] ] ].
s contents
" 2>&1 | grep -v Deprecation
