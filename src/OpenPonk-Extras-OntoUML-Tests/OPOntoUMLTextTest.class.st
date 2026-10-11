"
Adding OntoUML elements from text: the notation, problems reported by line with suggestions, the import into a diagram as one undoable step, and the dialog.
"
Class {
	#name : 'OPOntoUMLTextTest',
	#superclass : 'OPOntoUMLAssistantTestCase',
	#category : 'OpenPonk-Extras-OntoUML-Tests',
	#package : 'OpenPonk-Extras-OntoUML-Tests'
}

{ #category : 'helpers' }
OPOntoUMLTextTest >> classNamed: aString [

	^ diagramController model packagedElements
		  detect: [ :each | each class == OPUMLClass and: [ each name = aString ] ]
		  ifNone: [ nil ]
]

{ #category : 'helpers' }
OPOntoUMLTextTest >> import: aString [

	^ OPOntoUMLTextImport on: diagramController text: aString
]

{ #category : 'helpers' }
OPOntoUMLTextTest >> parse: aString [

	^ OPOntoUMLTextParser parse: aString
]

{ #category : 'tests - import' }
OPOntoUMLTextTest >> testAddFromTextCommandIsOnTheCanvas [

	| context |
	self openOntoUML.
	context := OPRoassalShapeContext
		           for: diagramController canvasPresenter
		           of: { diagramController canvas }.
	self assert: (OPOntoUMLAddFromTextCommand canBeExecutedInContext: context).
	self assert: (OPOntoUMLAddFromTextModelCommand canBeExecutedInEditor: workbench focusedEditor)
]

{ #category : 'tests - dialog' }
OPOntoUMLTextTest >> testDialogPreviewsAndAdds [

	| dialog created |
	self openOntoUML.
	dialog := OPOntoUMLTextDialog on: diagramController.

	dialog text: 'Osoba : Kid'.
	self assert: dialog import hasErrors.
	self deny: (dialog instVarNamed: #addButton) isEnabled.
	self assert: dialog add identicalTo: dialog.

	dialog text: 'Osoba : Kind
Student : Role -> Osoba'.
	self assert: (dialog instVarNamed: #addButton) isEnabled.
	self
		assert: dialog import planLines
		equals: #( '+ třída «Osoba» (Kind)' '+ třída «Student» (Role)' '+ generalizace Student → Osoba' ).
	created := dialog add.

	self assert: created size equals: 3.
	self assert: (self classNamed: 'Student') notNil.
	self assert: (dialog instVarNamed: #textInput) text asString isEmpty
]

{ #category : 'tests - import' }
OPOntoUMLTextTest >> testImportChangesStereotypeOfExistingClass [

	| person import |
	self openOntoUML.
	person := self class: 'Kind' named: 'Osoba'.
	import := self import: 'osoba : Category'.

	self deny: import hasErrors.
	self assert: import planLines equals: #( '~ «Osoba»: stereotyp Kind → Category' ).
	import apply.
	self assert: (self stereotypeOf: person) equals: 'Category'
]

{ #category : 'tests - import' }
OPOntoUMLTextTest >> testImportCreatesEverythingInOneUndoableStep [

	| person before import created study student ends set mediation |
	self openOntoUML.
	person := self class: 'Kind' named: 'Osoba'.
	"The new model already holds the CommonTypes package of data types."
	before := diagramController model packagedElements asArray.
	import := self import: (OPOntoUMLTexts at: #'template.relator.text') , '
Dítě, Dospělý : Phase -> Osoba {dc}
Studium -- Osoba : eviduje'.
	self deny: import hasErrors.

	created := import apply.

	self assert: (self classNamed: 'Osoba') identicalTo: person model.
	self assert: (diagramController model packagedElements select: [ :each | each class == OPUMLClass ]) size equals: 6.
	self assert: (OPOntoUMLStereotypeCatalog stereotypeNameOf: (self classNamed: 'Studium')) equals: 'Relator'.
	student := self classNamed: 'Student'.
	self assert: student generalizations first general identicalTo: person model.
	set := (self classNamed: 'Dítě') generalizations first generalizationSets first.
	self assert: set isDisjoint & set isCovering.
	self assert: set generalizations size equals: 2.
	study := self classNamed: 'Studium'.
	mediation := diagramController model packagedElements detect: [ :each |
		             (each isKindOf: OPUMLAssociation) and: [
			             (each memberEnds collect: [ :end | end type ]) asSet = { study. student } asSet ] ].
	self assert: (OPOntoUMLStereotypeCatalog stereotypeNameOf: mediation) equals: 'Mediation'.
	ends := mediation memberEnds detect: [ :each | each type == study ].
	self assert: ends lowerValue value equals: 1.
	self assert: ends upperValue value equals: '*'.
	self assert: ((diagramController model packagedElements select: [ :each | each isKindOf: OPUMLAssociation ])
			 anySatisfy: [ :each | each name = 'eviduje' ]).
	self assert: (diagramController selectedControllers includesAll: created).
	"The roles have their relator: the check finds nothing."
	self assert: (OPOntoUMLChecker problemsIn: diagramController model) isEmpty.

	diagramController undoManager undo.
	self
		assert: (diagramController model packagedElements reject: [ :each | each isKindOf: OPUMLGeneralizationSet ])
				asArray
		equals: before
]

{ #category : 'tests - import' }
OPOntoUMLTextTest >> testImportReusesClassesAndSuggestsTypos [

	| import |
	self openOntoUML.
	self class: 'Kind' named: 'Univerzita'.
	import := self import: 'Student : Role -> osoba
Osoba : Kid
Studium : Relator
Studium -- Univrzita : na
Studium --mediaton-- Student'.

	self assert: import errorLines asArray equals: #(
			'Řádek 2: neznámý stereotyp «Kid», myslel jsi «Kind»?'
			'Řádek 4: neznámá třída «Univrzita», myslel jsi «Univerzita»?'
			'Řádek 5: neznámý stereotyp «mediaton», myslel jsi «Mediation»?' ).

	import := self import: 'Studium : Relator
Studium 1 --mediation-- 1..* univerzita'.
	self deny: import hasErrors.
	self
		assert: import planLines
		equals: #( '+ třída «Studium» (Relator)' '+ vztah Mediation: Studium [1] – Univerzita [1..*]' )
]

{ #category : 'tests - import' }
OPOntoUMLTextTest >> testExistingGeneralizationIsNotAddedAgain [

	| person student import |
	self openOntoUML.
	person := self class: 'Kind' named: 'Osoba'.
	student := self class: 'Role' named: 'Student'.
	self generalize: student to: person.

	import := self import: 'Student -> Osoba'.

	self assert: import isEmpty.
	self assert: import planLines equals: #( '= generalizace Student → Osoba už v diagramu je' )
]

{ #category : 'tests - notation' }
OPOntoUMLTextTest >> testParserReadsTheNotation [

	| parser statements |
	parser := self parse: '# poznámka
Osoba : Kind
Student, "Učitel, starší" : Role -> Osoba   // komentář
«Kind» Auto
<<collective>> Flotila
Dítě, Dospělý : Phase -> Osoba {disjoint, complete}
Dítě, Dospělý -> Osoba {OI}
Studium 1..* --mediation-- 1 Student : studuje
Řidič -- Autobusová linka
Auto 0..1 ---- 2...3,5 Kolo'.

	self assert: parser errors isEmpty.
	statements := parser statements.
	self assert: (statements collect: [ :each | each kind ]) asArray equals: #( #class #class #class #class #class #generalization #relation #relation #relation ).
	self assert: (statements collect: [ :each | each line ]) asArray equals: #( 2 3 4 5 6 7 8 9 10 ).
	self assert: statements second names equals: #( 'Student' 'Učitel, starší' ).
	self assert: statements second parents equals: #( 'Osoba' ).
	self assert: statements third stereotype equals: 'Kind'.
	self assert: statements fourth stereotype equals: 'collective'.
	self assert: (OPOntoUMLTextParser setFlagsFrom: statements fifth setText) equals: #( true true ).
	self assert: (OPOntoUMLTextParser setFlagsFrom: (statements at: 6) setText) equals: #( false false ).
	self assert: (OPOntoUMLTextParser setFlagsFrom: 'complete, overlapping') equals: #( false true ).
	(statements at: 7) in: [ :relation |
		self assert: relation source equals: 'Studium'.
		self assert: relation sourceMultiplicity equals: '1..*'.
		self assert: relation relationStereotype equals: 'mediation'.
		self assert: relation targetMultiplicity equals: '1'.
		self assert: relation target equals: 'Student'.
		self assert: relation label equals: 'studuje' ].
	(statements at: 8) in: [ :relation |
		self assert: relation source equals: 'Řidič'.
		self assert: relation target equals: 'Autobusová linka'.
		self assert: relation relationStereotype isNil.
		self assert: relation label isNil ].
	(statements at: 9) in: [ :relation |
		self assert: relation sourceMultiplicity equals: '0..1'.
		self assert: relation targetMultiplicity equals: '2...3,5'.
		self assert: relation relationStereotype isNil ]
]

{ #category : 'tests - notation' }
OPOntoUMLTextTest >> testParserReportsProblemsByLine [

	| parser |
	parser := self parse: 'Osoba
Dítě : Phase {dc}
Dítě -> Osoba {neco}
Studium --mediation--
A, B -> C, D {dc}'.

	self assert: parser statements isEmpty.
	self assert: (parser errors collect: [ :each | each key ]) asArray equals: #( 1 2 3 4 5 ).
	self assert: parser errors first value equals: 'u «Osoba» chybí stereotyp, napiš třeba «Osoba : Kind»'.
	self assert: (parser errors at: 3) value equals: 'nerozumím množině «neco», napiš třeba {disjoint, complete} nebo {dc}'
]
