#!/bin/bash
# Obnovi cisty image z build/pristine, nahraje src/ (BaselineOfOpenPonkExtras) a ulozi.
# Pri jakekoli chybe nahravani skonci nenulove a image zustane cisty (ne napul upraveny).
# Kontroluje i to, ze se nacetla kazda trida/trait ze src/ (Tonel tise vynecha soubor se syntaktickou chybou).
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMG="$DIR/build/image"
pgrep -f "$IMG/openponk-plugins.image" >/dev/null && { echo "Vyvojovy OpenPonk bezi, nejdriv ho zavri." >&2; exit 1; }
cp "$DIR/build/pristine/openponk-plugins.image" "$DIR/build/pristine/openponk-plugins.changes" "$IMG/"
"$DIR/build/Pharo.app/Contents/MacOS/Pharo" --headless "$IMG/openponk-plugins.image" eval "
| before after |
before := Undeclared keys asSet.
Metacello new baseline: 'OpenPonkExtras'; repository: 'tonel://$DIR/src'; load: #('all').
after := Undeclared keys asSet copyWithoutAll: before.
after ifNotEmpty: [ Error signal: 'Nove nedeklarovane promenne: ', after asArray printString ].
((('$DIR/src' asFileReference allChildrenMatching: '*.class.st'), ('$DIR/src' asFileReference allChildrenMatching: '*.trait.st'))
	collect: [ :file | (file basename copyUpTo: \$.) asSymbol ]
	thenReject: [ :name | Smalltalk globals includesKey: name ]) ifNotEmpty: [ :missing |
		Error signal: 'Nenactene tridy (chyba syntaxe?): ', missing asArray printString ].
(Smalltalk at: #OPExtrasSetup ifAbsent: [ nil ]) ifNotNil: [ :setup | setup afterBuild ].
Smalltalk snapshot: true andQuit: true
"
echo "Build OK"
