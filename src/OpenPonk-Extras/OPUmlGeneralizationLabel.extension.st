Extension { #name : 'OPUmlGeneralizationLabel' }

{ #category : '*OpenPonk-Extras' }
OPUmlGeneralizationLabel >> defaultTextForSet: aGeneralizationSet on: aStream [
	"Override of OpenPonk-ClassEditor: an unnamed set is not labelled 'set', and the default values incomplete / overlapping are shown as well when #showIncomplete / #showOverlapping say so (they were never consulted)."

	| name properties |
	name := (aGeneralizationSet name ifNil: [ '' ]) trim.
	name ifNotEmpty: [ aStream << name << ' ' ].
	properties := OrderedCollection new.
	aGeneralizationSet isCovering == true
		ifTrue: [ properties add: 'complete' ]
		ifFalse: [ self showIncomplete ifTrue: [ properties add: 'incomplete' ] ].
	aGeneralizationSet isDisjoint == true
		ifTrue: [ properties add: 'disjoint' ]
		ifFalse: [ self showOverlapping ifTrue: [ properties add: 'overlapping' ] ].
	aStream << '{'.
	properties do: [ :each | aStream << each ] separatedBy: [ aStream << ', ' ].
	aStream << '}'
]

{ #category : '*OpenPonk-Extras' }
OPUmlGeneralizationLabel >> showIncomplete [
	"Override of OpenPonk-ClassEditor (was false): OntoUML diagrams read {incomplete, overlapping} explicitly."

	^ true
]

{ #category : '*OpenPonk-Extras' }
OPUmlGeneralizationLabel >> showOverlapping [
	"Override of OpenPonk-ClassEditor (was false), see #showIncomplete."

	^ true
]
