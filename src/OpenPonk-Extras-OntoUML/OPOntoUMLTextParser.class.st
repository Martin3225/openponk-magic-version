"
I read the text for adding OntoUML elements, one statement per line (see OPOntoUMLTextStatement):

	Person : Kind
	Student, Teacher : Role -> Person
	«Kind» Car                                    (or <<Kind>> Car)
	Child, Adult : Phase -> Person {disjoint, complete}
	Child, Adult -> Person {dc}                   (dc, di, oc, oi)
	Study 1..* --mediation-- 1 Student : studies
	Driver -- Car : drives                        (no stereotype)

Names may contain spaces; a name with a comma, colon or the like goes into double quotes. A multiplicity is written next to the class it belongs to. Lines starting with # or // are comments.

I only check the form of the lines; whether classes and stereotypes exist is checked by OPOntoUMLTextImport. Problems are collected per line, so the user sees all of them at once.
"
Class {
	#name : 'OPOntoUMLTextParser',
	#superclass : 'Object',
	#instVars : [
		'statements',
		'errors'
	],
	#category : 'OpenPonk-Extras-OntoUML-Text',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Text'
}

{ #category : 'parsing' }
OPOntoUMLTextParser class >> parse: aString [

	^ self new
		  parse: aString;
		  yourself
]

{ #category : 'sets' }
OPOntoUMLTextParser class >> setFlagsFrom: aString [
	"{ isDisjoint. isCovering } from 'disjoint, complete', 'complete, overlapping', 'dc', 'D,I'...; UML defaults (disjoint, incomplete) for what is left out."

	| words disjoint covering code |
	words := (aString asLowercase substrings: ', ') reject: [ :each | each isEmpty ].
	code := '' join: words.
	(code size = 2 and: [ ('do' includes: code first) and: [ 'ci' includes: code second ] ])
		ifTrue: [
			^ {
				  (code first = $d).
				  (code second = $c) } ].
	disjoint := true.
	covering := false.
	words do: [ :each |
		each = 'disjoint'
			ifTrue: [ disjoint := true ]
			ifFalse: [
				each = 'overlapping'
					ifTrue: [ disjoint := false ]
					ifFalse: [
						each = 'complete'
							ifTrue: [ covering := true ]
							ifFalse: [
								each = 'incomplete'
									ifTrue: [ covering := false ]
									ifFalse: [ self signal: #'text.badSet' with: { aString } ] ] ] ] ].
	^ {
		  disjoint.
		  covering }
]

{ #category : 'errors' }
OPOntoUMLTextParser class >> signal: aKey with: anArray [

	OPOntoUMLTextError signal: (OPOntoUMLTexts at: aKey with: anArray)
]

{ #category : 'parsing' }
OPOntoUMLTextParser >> classOrGeneralizationFrom: aString [

	| rest stereotype setText arrow namesPart parentsPart colon names parents |
	rest := aString.
	(rest beginsWith: '«') ifTrue: [
		| close |
		close := rest indexOf: $».
		close = 0 ifTrue: [ self signal: #'text.cannotParse' ].
		stereotype := (rest copyFrom: 2 to: close - 1) trimBoth.
		rest := (rest allButFirst: close) trimBoth ].
	(rest beginsWith: '<<') ifTrue: [
		| close |
		close := rest indexOfSubCollection: '>>'.
		close = 0 ifTrue: [ self signal: #'text.cannotParse' ].
		stereotype := (rest copyFrom: 3 to: close - 1) trimBoth.
		rest := (rest allButFirst: close + 1) trimBoth ].
	(rest endsWith: '}') ifTrue: [
		| open |
		open := self lastIndexOutsideQuotesOf: '{' in: rest.
		open = 0 ifTrue: [ self signal: #'text.cannotParse' ].
		setText := (rest copyFrom: open + 1 to: rest size - 1) trimBoth.
		self class setFlagsFrom: setText.
		rest := (rest first: open - 1) trimBoth ].
	arrow := self indexOutsideQuotesOf: '->' in: rest.
	arrow > 0
		ifTrue: [
			namesPart := rest first: arrow - 1.
			parentsPart := rest allButFirst: arrow + 1 ]
		ifFalse: [ namesPart := rest ].
	colon := self indexOutsideQuotesOf: ':' in: namesPart.
	colon > 0 ifTrue: [
		stereotype ifNotNil: [ self signal: #'text.twoStereotypes' ].
		stereotype := (namesPart allButFirst: colon) trimBoth.
		namesPart := namesPart first: colon - 1 ].
	names := self namesIn: namesPart.
	names ifEmpty: [ self signal: #'text.missingName' ].
	parents := parentsPart
		           ifNil: [ #(  ) ]
		           ifNotNil: [ self namesIn: parentsPart ].
	(arrow > 0 and: [ parents isEmpty ]) ifTrue: [ self signal: #'text.missingParent' ].
	(stereotype isEmptyOrNil and: [ parents isEmpty ]) ifTrue: [
		self signal: #'text.missingStereotype' with: { names first } ].
	(setText notNil and: [ parents isEmpty ]) ifTrue: [ self signal: #'text.setNeedsParent' ].
	(setText notNil and: [ parents size > 1 ]) ifTrue: [ self signal: #'text.setNeedsOneParent' ].
	^ OPOntoUMLTextStatement new
		  kind: (stereotype isEmptyOrNil
				   ifTrue: [ #generalization ]
				   ifFalse: [ #class ]);
		  names: names;
		  stereotype: (stereotype isEmptyOrNil ifFalse: [ stereotype ]);
		  parents: parents;
		  setText: setText;
		  yourself
]

{ #category : 'accessing' }
OPOntoUMLTextParser >> errors [
	"Line number -> message."

	^ errors
]

{ #category : 'private' }
OPOntoUMLTextParser >> indexOutsideQuotesOf: aSubstring in: aString [
	"First index of aSubstring in aString outside double quotes, or 0."

	| inQuotes |
	inQuotes := false.
	1 to: aString size - aSubstring size + 1 do: [ :index |
		(aString at: index) = $" ifTrue: [ inQuotes := inQuotes not ].
		(inQuotes not and: [ (aString copyFrom: index to: index + aSubstring size - 1) = aSubstring ])
			ifTrue: [ ^ index ] ].
	^ 0
]

{ #category : 'private' }
OPOntoUMLTextParser >> isMultiplicity: aString [

	^ aString matchesRegex: '(\d+([.,]\d+)?|\*)(\.\.\.?(\d+([.,]\d+)?|\*))?'
]

{ #category : 'private' }
OPOntoUMLTextParser >> lastIndexOutsideQuotesOf: aSubstring in: aString [

	| found index |
	found := 0.
	index := 0.
	[
	index := self
		         indexOutsideQuotesOf: aSubstring
		         in: (aString allButFirst: found).
	index > 0 ] whileTrue: [ found := found + index ].
	^ found
]

{ #category : 'private' }
OPOntoUMLTextParser >> nameFrom: aString [
	"Trimmed, with single spaces, without surrounding double quotes."

	| name |
	name := aString trimBoth.
	(name size >= 2 and: [ name first = $" and: [ name last = $" ] ]) ifTrue: [
		^ (name copyFrom: 2 to: name size - 1) trimBoth ].
	^ ' ' join: name substrings
]

{ #category : 'private' }
OPOntoUMLTextParser >> namesIn: aString [
	"Names separated by commas (outside double quotes)."

	| names rest comma |
	names := OrderedCollection new.
	rest := aString.
	[ (comma := self indexOutsideQuotesOf: ',' in: rest) > 0 ] whileTrue: [
		names add: (self nameFrom: (rest first: comma - 1)).
		rest := rest allButFirst: comma ].
	names add: (self nameFrom: rest).
	^ (names reject: [ :each | each isEmpty ]) asArray
]

{ #category : 'parsing' }
OPOntoUMLTextParser >> parse: aString [

	statements := OrderedCollection new.
	errors := OrderedCollection new.
	aString lines withIndexDo: [ :each :index | self parseLine: each number: index ]
]

{ #category : 'parsing' }
OPOntoUMLTextParser >> parseLine: aString number: anInteger [

	| text |
	text := self withoutComment: aString.
	text ifEmpty: [ ^ self ].
	[
	statements add: ((self statementFrom: text)
			 line: anInteger;
			 yourself) ]
		on: OPOntoUMLTextError
		do: [ :error | errors add: anInteger -> error messageText ]
]

{ #category : 'parsing' }
OPOntoUMLTextParser >> relationFrom: aString [

	| dashes left rest stereotypeEnd stereotype right colon label source target |
	dashes := self indexOutsideQuotesOf: '--' in: aString.
	left := (aString first: dashes - 1) trimBoth.
	rest := aString allButFirst: dashes + 1.
	stereotypeEnd := self indexOutsideQuotesOf: '--' in: rest.
	right := rest.
	(stereotypeEnd > 0 and: [
		 (rest first: stereotypeEnd - 1) trimBoth allSatisfy: [ :each | each isLetter ] ]) ifTrue: [
		stereotype := (rest first: stereotypeEnd - 1) trimBoth.
		stereotype ifEmpty: [ stereotype := nil ].
		right := rest allButFirst: stereotypeEnd + 1 ].
	colon := self indexOutsideQuotesOf: ':' in: right.
	colon > 0 ifTrue: [
		label := self nameFrom: (right allButFirst: colon).
		label ifEmpty: [ label := nil ].
		right := right first: colon - 1 ].
	source := self splitLastMultiplicityOf: left trimBoth.
	target := self splitFirstMultiplicityOf: right trimBoth.
	(source first isEmpty or: [ target second isEmpty ]) ifTrue: [
		self signal: #'text.relationNeedsEnds' ].
	^ OPOntoUMLTextStatement new
		  kind: #relation;
		  source: source first;
		  sourceMultiplicity: source second;
		  relationStereotype: stereotype;
		  targetMultiplicity: target first;
		  target: target second;
		  label: label;
		  yourself
]

{ #category : 'errors' }
OPOntoUMLTextParser >> signal: aKey [

	self signal: aKey with: #(  )
]

{ #category : 'errors' }
OPOntoUMLTextParser >> signal: aKey with: anArray [

	self class signal: aKey with: anArray
]

{ #category : 'private' }
OPOntoUMLTextParser >> splitFirstMultiplicityOf: aString [
	"{ multiplicity or nil. name }"

	| tokens |
	tokens := aString substrings.
	(tokens size > 1 and: [ self isMultiplicity: tokens first ]) ifTrue: [
		^ {
			  tokens first.
			  (self nameFrom: (aString allButFirst: tokens first size)) } ].
	^ {
		  nil.
		  (self nameFrom: aString) }
]

{ #category : 'private' }
OPOntoUMLTextParser >> splitLastMultiplicityOf: aString [
	"{ name. multiplicity or nil }"

	| tokens |
	tokens := aString substrings.
	(tokens size > 1 and: [ self isMultiplicity: tokens last ]) ifTrue: [
		^ {
			  (self nameFrom: (aString allButLast: tokens last size)).
			  tokens last } ].
	^ {
		  (self nameFrom: aString).
		  nil }
]

{ #category : 'parsing' }
OPOntoUMLTextParser >> statementFrom: aString [

	(self indexOutsideQuotesOf: '--' in: aString) > 0 ifTrue: [ ^ self relationFrom: aString ].
	((self indexOutsideQuotesOf: ':' in: aString) > 0 or: [
		 (self indexOutsideQuotesOf: '->' in: aString) > 0 or: [
			 (aString beginsWith: '«') or: [ aString beginsWith: '<<' ] ] ]) ifTrue: [
		^ self classOrGeneralizationFrom: aString ].
	self signal: #'text.missingStereotype' with: { (self nameFrom: aString) }
]

{ #category : 'accessing' }
OPOntoUMLTextParser >> statements [

	^ statements
]

{ #category : 'private' }
OPOntoUMLTextParser >> withoutComment: aString [
	"Without a whole-line comment (# or //) or a comment after a space."

	| text index |
	text := aString trimBoth.
	((text beginsWith: '#') or: [ text beginsWith: '//' ]) ifTrue: [ ^ '' ].
	#( ' #' ' //' ) do: [ :each |
		index := self indexOutsideQuotesOf: each in: text.
		index > 0 ifTrue: [ text := (text first: index - 1) trimBoth ] ].
	^ text
]
