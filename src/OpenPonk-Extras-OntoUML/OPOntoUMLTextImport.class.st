"
I add OntoUML elements written as text (see OPOntoUMLTextParser) to a diagram.

First I analyze the text against the diagram, without changing anything: classes already shown in the diagram are reused by name (case does not matter), new ones need a stereotype, misspelled stereotypes and class names get a suggestion, and the result is a plan (#planLines) and a list of problems by line (#errorLines). The dialog shows both while the user types.

#apply then makes the plan as one undoable step: new classes are placed in rows by their generalizations (parents above children) next to what is in the diagram, or under their parent when it already is in the diagram; then the diagram is tidied (OPDiagramTidier) and the new elements are selected.
"
Class {
	#name : 'OPOntoUMLTextImport',
	#superclass : 'Object',
	#instVars : [
		'diagramController',
		'builder',
		'text',
		'errors',
		'declarations',
		'stereotypeChanges',
		'generalizations',
		'existingGeneralizations',
		'sets',
		'relations',
		'controllersByName',
		'invalidNames'
	],
	#category : 'OpenPonk-Extras-OntoUML-Text',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Text'
}

{ #category : 'instance creation' }
OPOntoUMLTextImport class >> on: aDiagramController text: aString [

	^ self new
		  setDiagramController: aDiagramController text: aString;
		  analyze;
		  yourself
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> addError: aKey with: anArray line: anInteger [

	errors add: anInteger -> (OPOntoUMLTexts at: aKey with: anArray)
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> addGeneralizationsOf: aStatement [

	| children parent pairs |
	aStatement parents ifEmpty: [ ^ self ].
	children := aStatement names collect: [ :each | self resolve: each line: aStatement line ].
	pairs := OrderedCollection new.
	aStatement parents do: [ :parentName |
		parent := self resolve: parentName line: aStatement line.
		children do: [ :child |
			(child notNil and: [ parent notNil ]) ifTrue: [
				(self is: child sameAs: parent)
					ifTrue: [ self addError: #'text.selfGeneralization' with: { (self nameOf: child) } line: aStatement line ]
					ifFalse: [
						pairs add: child -> parent.
						(self hasGeneralizationFrom: child to: parent) ifFalse: [
							((self isExisting: child) and: [ self isExisting: parent ])
								ifTrue: [
									(self existingGeneralizationFrom: child to: parent)
										ifNil: [ generalizations add: child -> parent ]
										ifNotNil: [ existingGeneralizations add: child -> parent ] ]
								ifFalse: [ generalizations add: child -> parent ] ] ] ] ] ].
	(aStatement setText notNil and: [ pairs notEmpty ]) ifTrue: [
		sets add: {
				(pairs collect: [ :each | each key ]) asArray.
				pairs first value.
				(OPOntoUMLTextParser setFlagsFrom: aStatement setText) } ]
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> addRelation: aStatement [

	| source target stereotype valid |
	valid := true.
	source := self resolve: aStatement source line: aStatement line.
	target := self resolve: aStatement target line: aStatement line.
	(source isNil or: [ target isNil ]) ifTrue: [ valid := false ].
	stereotype := self relationStereotypeNamed: aStatement relationStereotype line: aStatement line.
	stereotype ifNil: [ valid := false ].
	{
		aStatement sourceMultiplicity.
		aStatement targetMultiplicity } do: [ :each |
		each ifNotNil: [
			[ OPMultiplicityParser boundsFrom: each ]
				on: OPInvalidMultiplicity
				do: [
					valid := false.
					self addError: #'text.badMultiplicity' with: { each } line: aStatement line ] ] ].
	valid ifTrue: [
		relations add: {
				source.
				target.
				stereotype.
				aStatement } ]
]

{ #category : 'analysis' }
OPOntoUMLTextImport >> analyze [

	| parser |
	parser := OPOntoUMLTextParser parse: text.
	errors := parser errors asOrderedCollection.
	declarations := OrderedDictionary new.
	invalidNames := Set new.
	stereotypeChanges := OrderedCollection new.
	generalizations := OrderedCollection new.
	existingGeneralizations := OrderedCollection new.
	sets := OrderedCollection new.
	relations := OrderedCollection new.
	parser statements do: [ :each |
		each isClass ifTrue: [
			each names do: [ :name | self declare: name stereotype: each stereotype line: each line ] ] ].
	parser statements do: [ :each |
		(each isClass or: [ each isGeneralization ]) ifTrue: [ self addGeneralizationsOf: each ].
		each isRelation ifTrue: [ self addRelation: each ] ].
	generalizations := self withoutDuplicatePairs: generalizations.
	existingGeneralizations := self withoutDuplicatePairs: existingGeneralizations
]

{ #category : 'applying' }
OPOntoUMLTextImport >> apply [
	"Make the plan as one undoable step and answer the controllers of the new elements."

	| created |
	self hasErrors ifTrue: [ OPDiagramBuildError signal: self errorLines first ].
	created := OrderedCollection new.
	controllersByName := Dictionary new.
	builder inTransactionLabeled: (OPOntoUMLTexts at: #'text.undo') do: [
		| positions |
		positions := self positionsOfNewClasses.
		self newClasses do: [ :each |
			| controller |
			controller := builder
				              createNode: each value
				              in: nil
				              topLeft: (positions at: each key)
				              named: each key.
			controllersByName at: each key asLowercase put: controller.
			created add: controller ].
		stereotypeChanges do: [ :each |
			builder setStereotypeNamed: each value of: (self controllerOf: each key) ].
		generalizations do: [ :each |
			created add: (builder
					 connect: 'Generalization'
					 from: (self controllerOf: each key)
					 to: (self controllerOf: each value)
					 named: nil) ].
		sets do: [ :each | self applySet: each ].
		relations do: [ :each | created add: (self applyRelation: each) ].
		(OPDiagramTidier on: diagramController) tidy ].
	diagramController selectControllers: created asArray.
	diagramController canvas signalUpdate.
	^ created asArray
]

{ #category : 'private - applying' }
OPOntoUMLTextImport >> applyRelation: aRelation [
	"{ source. target. palette entry name. statement }"

	| statement source target edge ends |
	statement := aRelation fourth.
	source := self controllerOf: aRelation first.
	target := self controllerOf: aRelation second.
	edge := builder
		        connect: aRelation third
		        from: source
		        to: target
		        named: statement label.
	ends := self endsOf: edge model from: source model to: target model.
	statement sourceMultiplicity ifNotNil: [ :multiplicity |
		builder setMultiplicity: multiplicity ofEnd: ends first in: edge ].
	statement targetMultiplicity ifNotNil: [ :multiplicity |
		builder setMultiplicity: multiplicity ofEnd: ends second in: edge ].
	^ edge
]

{ #category : 'private - applying' }
OPOntoUMLTextImport >> applySet: aSet [
	"{ children. parent. { isDisjoint. isCovering } }"

	| parent generalizationsOfSet |
	parent := (self controllerOf: aSet second) model.
	generalizationsOfSet := aSet first collect: [ :each |
		                        (self controllerOf: each) model generalizations detect: [ :generalization |
			                        generalization general == parent ] ].
	(OPOntoUMLGeneralizationSets on: diagramController)
		setGeneralizations: generalizationsOfSet
		disjoint: aSet third first
		covering: aSet third second
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> availableStereotypeNames [

	^ (builder stereotypes collect: [ :each | each name ]) asSet
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> closestOf: aCollectionOfStrings to: aString [
	"The most similar string, if it is similar enough to be a likely typo; nil otherwise."

	| best bestDistance |
	bestDistance := SmallInteger maxVal.
	aCollectionOfStrings do: [ :each |
		| distance |
		distance := self distanceFrom: aString asLowercase to: each asLowercase.
		distance < bestDistance ifTrue: [
			best := each.
			bestDistance := distance ] ].
	^ bestDistance <= (2 max: aString size // 3)
		  ifTrue: [ best ]
		  ifFalse: [ nil ]
]

{ #category : 'private - applying' }
OPOntoUMLTextImport >> controllerOf: aReference [
	"A class named in the text (a String: created now) or one in the diagram (its model)."

	aReference isString ifTrue: [ ^ controllersByName at: aReference asLowercase ].
	^ diagramController controllerForModel: aReference
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> declare: aName stereotype: aStereotype line: anInteger [

	| stereotype existing |
	stereotype := self classStereotypeNamed: aStereotype line: anInteger.
	stereotype ifNil: [
		"Its line has an error already; lines using the class should not report it again."
		invalidNames add: aName asLowercase.
		^ self ].
	(declarations keys detect: [ :each | each asLowercase = aName asLowercase ] ifNone: [ nil ])
		ifNotNil: [ :declared |
			(declarations at: declared) = stereotype ifFalse: [
				self
					addError: #'text.conflictingStereotypes'
					with: {
							declared.
							(declarations at: declared).
							stereotype }
					line: anInteger ].
			^ self ].
	existing := self existingClassNamed: aName.
	existing
		ifNil: [ declarations at: aName put: stereotype ]
		ifNotNil: [
			declarations at: (self nameOf: existing) put: stereotype.
			(OPOntoUMLStereotypeCatalog stereotypeNameOf: existing) = stereotype ifFalse: [
				stereotypeChanges add: existing -> stereotype ] ]
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> classStereotypeNamed: aString line: anInteger [
	"The stereotype name as the profile spells it, or nil (and an error)."

	| names |
	names := OPOntoUMLStereotypeCatalog classStereotypeNames select: [ :each |
		         self availableStereotypeNames includes: each ].
	names
		detect: [ :each | each asLowercase = aString asLowercase ]
		ifFound: [ :found | ^ found ].
	(OPOntoUMLStereotypeCatalog relationStereotypeNames anySatisfy: [ :each |
		 each asLowercase = aString asLowercase ])
		ifTrue: [ self addError: #'text.relationStereotypeForClass' with: { aString } line: anInteger ]
		ifFalse: [ self addUnknownStereotype: aString among: names line: anInteger ].
	^ nil
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> addUnknownStereotype: aString among: aCollectionOfNames line: anInteger [

	errors add: anInteger
		->
			((OPOntoUMLTexts at: #'text.unknownStereotype' with: { aString })
			 , ((self closestOf: aCollectionOfNames to: aString)
					  ifNil: [ '' ]
					  ifNotNil: [ :suggestion | OPOntoUMLTexts at: #'text.didYouMean' with: { suggestion } ]))
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> distanceFrom: aString to: anotherString [
	"Levenshtein distance."

	| previous current |
	previous := (0 to: anotherString size) asArray.
	aString doWithIndex: [ :character :i |
		current := Array new: anotherString size + 1.
		current at: 1 put: i.
		anotherString doWithIndex: [ :otherCharacter :j |
			current at: j + 1 put: ((((previous at: j + 1) + 1) min: (current at: j) + 1) min:
					 (previous at: j) + (character = otherCharacter
						  ifTrue: [ 0 ]
						  ifFalse: [ 1 ])) ].
		previous := current ].
	^ previous last
]

{ #category : 'private - applying' }
OPOntoUMLTextImport >> endsOf: anAssociation from: aSourceClass to: aTargetClass [
	"{ end at the source class. end at the target class }"

	| ends sourceEnd |
	ends := anAssociation memberEnds asArray.
	aSourceClass == aTargetClass ifTrue: [ ^ ends ].
	sourceEnd := ends detect: [ :each | each type == aSourceClass ].
	^ {
		  sourceEnd.
		  (ends detect: [ :each | each ~~ sourceEnd ]) }
]

{ #category : 'accessing' }
OPOntoUMLTextImport >> errorLines [
	"Problems as 'Line 3: ...', in the order of the lines."

	^ ((errors asArray sort: [ :a :b | a key <= b key ]) collect: [ :each |
		   OPOntoUMLTexts at: #'text.line' with: {
				   each key printString.
				   each value } ]) asArray
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> existingClassNamed: aString [

	| classes |
	classes := self existingClasses.
	classes
		detect: [ :each | (self nameOf: each) = aString ]
		ifFound: [ :found | ^ found ].
	^ classes
		  detect: [ :each | (self nameOf: each) asLowercase = aString asLowercase ]
		  ifNone: [ nil ]
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> existingClasses [
	"Classes shown in the diagram."

	^ (diagramController controllers
		   collect: [ :each | each model ]
		   thenSelect: [ :each |
			   (each respondsTo: #generalizations) and: [
				   (each isKindOf: OPUMLGeneralization) not and: [
					   (each isKindOf: OPUMLGeneralizationSet) not and: [
						   (each isKindOf: OPUMLAssociation) not and: [ each ~~ diagramController model ] ] ] ] ])
		  asSet asArray
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> existingGeneralizationFrom: aChild to: aParent [

	^ aChild generalizations
		  detect: [ :each | each general == aParent ]
		  ifNone: [ nil ]
]

{ #category : 'testing' }
OPOntoUMLTextImport >> hasErrors [

	^ errors notEmpty
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> hasGeneralizationFrom: aChild to: aParent [
	"Already planned by an earlier line."

	^ generalizations anySatisfy: [ :each |
		  (self is: each key sameAs: aChild) and: [ self is: each value sameAs: aParent ] ]
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> is: aReference sameAs: anotherReference [

	(aReference isString and: [ anotherReference isString ]) ifTrue: [
		^ aReference asLowercase = anotherReference asLowercase ].
	^ aReference == anotherReference
]

{ #category : 'testing' }
OPOntoUMLTextImport >> isEmpty [
	"Nothing to add or change."

	^ self newClasses isEmpty and: [
		  stereotypeChanges isEmpty and: [
			  generalizations isEmpty and: [ sets isEmpty and: [ relations isEmpty ] ] ] ]
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> isExisting: aReference [

	^ aReference isString not
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> nameOf: aReference [

	^ aReference isString
		  ifTrue: [ aReference ]
		  ifFalse: [ OPOntoUMLStereotypeCatalog displayNameOf: aReference ]
]

{ #category : 'accessing' }
OPOntoUMLTextImport >> newClasses [
	"Name -> stereotype of the classes to create."

	^ (declarations associations reject: [ :each | (self existingClassNamed: each key) notNil ])
		  asArray
]

{ #category : 'accessing' }
OPOntoUMLTextImport >> planLines [
	"What will be added or changed, one line each."

	| lines |
	lines := OrderedCollection new.
	self newClasses do: [ :each |
		lines add: (OPOntoUMLTexts at: #'plan.newClass' with: {
					 each key.
					 each value }) ].
	stereotypeChanges do: [ :each |
		lines add: (OPOntoUMLTexts at: #'plan.changeStereotype' with: {
					 (self nameOf: each key).
					 ((OPOntoUMLStereotypeCatalog stereotypeNameOf: each key) ifNil: [
						  OPOntoUMLTexts at: #'stereotype.none' ]).
					 each value }) ].
	generalizations do: [ :each |
		lines add: (OPOntoUMLTexts at: #'plan.generalization' with: {
					 (self nameOf: each key).
					 (self nameOf: each value) }) ].
	existingGeneralizations do: [ :each |
		lines add: (OPOntoUMLTexts at: #'plan.existingGeneralization' with: {
					 (self nameOf: each key).
					 (self nameOf: each value) }) ].
	sets do: [ :each |
		lines add: (OPOntoUMLTexts at: #'plan.set' with: {
					 (self setNameOf: each third).
					 (', ' join: (each first collect: [ :child | self nameOf: child ])).
					 (self nameOf: each second) }) ].
	relations do: [ :each |
		lines add: (OPOntoUMLTexts at: #'plan.relation' with: {
					 each third.
					 (self relationEndText: each first multiplicity: each fourth sourceMultiplicity).
					 (self relationEndText: each second multiplicity: each fourth targetMultiplicity).
					 (each fourth label ifNil: [ '' ] ifNotNil: [ :label | ' «' , label , '»' ]) }) ].
	^ lines asArray
]

{ #category : 'private - applying' }
OPOntoUMLTextImport >> positionsOfNewClasses [
	"Top-left corners of the new classes: in rows by generalization (parents above) right of the diagram, under their parent when it already is in the diagram, and classes only related to others (relators...) below and between the classes they relate."

	| positions existingBounds origin newNames parentsOf levelOf levels attached related deferred |
	positions := Dictionary new.
	newNames := self newClasses collect: [ :each | each key ].
	existingBounds := self existingBounds.
	origin := existingBounds
		          ifNil: [ 60 @ 60 ]
		          ifNotNil: [ (existingBounds right + 140) @ existingBounds top ].
	parentsOf := [ :name |
	             generalizations
		             select: [ :each | each key isString and: [ each key asLowercase = name asLowercase ] ]
		             thenCollect: [ :each | each value ] ].
	related := [ :name |
	           relations
		           inject: OrderedCollection new
		           into: [ :all :each |
			           ((self is: each first sameAs: name) and: [ (self is: each second sameAs: name) not ])
				           ifTrue: [ all add: each second ].
			           ((self is: each second sameAs: name) and: [ (self is: each first sameAs: name) not ])
				           ifTrue: [ all add: each first ].
			           all ] ].
	attached := OrderedDictionary new.
	deferred := OrderedCollection new.
	levels := Dictionary new.
	levelOf := nil.
	levelOf := [ :name :visited |
	           levels at: name ifAbsent: [
		           | newParents level |
		           newParents := (parentsOf value: name) select: [ :each |
			                         each isString and: [ (visited includes: each asLowercase) not ] ].
		           level := newParents
			                    ifEmpty: [ 0 ]
			                    ifNotEmpty: [
				                    (newParents inject: 0 into: [ :max :each |
					                     max max: (levelOf value: each value: (visited copyWith: name asLowercase)) ])
				                    + 1 ].
		           levels at: name put: level ] ].
	newNames do: [ :name |
		| parents |
		parents := parentsOf value: name.
		parents isEmpty & (related value: name) notEmpty & (self isParent: name) not
			ifTrue: [ deferred add: name ]
			ifFalse: [
				(parents notEmpty and: [ parents allSatisfy: [ :each | each isString not ] ])
					ifTrue: [ (attached at: parents first ifAbsentPut: [ OrderedCollection new ]) add: name ]
					ifFalse: [ levelOf value: name value: #(  ) ] ] ].
	(levels values asSet asSortedCollection) do: [ :level |
		((levels keys select: [ :each | (levels at: each) = level ]) asSortedCollection: [ :a :b |
			 (newNames indexOf: a) <= (newNames indexOf: b) ]) doWithIndex: [ :name :index |
			positions at: name put: origin + (index - 1 * 170 @ (level * 150)) ] ].
	attached keysAndValuesDo: [ :parent :names |
		| rectangle |
		rectangle := (self rectangleOf: parent positions: positions) ifNil: [ origin extent: 0 @ 0 ].
		names doWithIndex: [ :name :index |
			positions
				at: name
				put: (rectangle center x - 50 + (index - 1 - (names size - 1 / 2) * 170)) rounded
					@ (rectangle bottom + 110) rounded ] ].
	deferred do: [ :name |
		| rectangles |
		rectangles := (related value: name)
			              collect: [ :each | self rectangleOf: each positions: positions ]
			              thenSelect: [ :each | each isNotNil ].
		positions at: name put: (rectangles
				 ifEmpty: [ origin + (0 @ (levels values inject: 0 into: [ :max :each | max max: each ]) + 1 * 150) ]
				 ifNotEmpty: [
					 ((rectangles inject: 0 into: [ :sum :each | sum + each center x ]) / rectangles size - 50) rounded
					 @ ((rectangles inject: 0 into: [ :max :each | max max: each bottom ]) + 120) rounded ]) ].
	^ positions
]

{ #category : 'private - applying' }
OPOntoUMLTextImport >> isParent: aName [
	"Some class of the text is to be a subclass of it."

	^ generalizations anySatisfy: [ :each | self is: each value sameAs: aName ]
]

{ #category : 'private - applying' }
OPOntoUMLTextImport >> rectangleOf: aReference positions: aDictionary [
	"Where a class is (in the diagram) or will be (a new class placed already, at its usual size)."

	aReference isString ifTrue: [
		^ (aDictionary at: aReference ifAbsent: [ nil ]) ifNotNil: [ :topLeft | topLeft extent: 100 @ 60 ] ].
	^ (diagramController controllerForModel: aReference ifNone: [ nil ]) ifNotNil: [ :controller |
		  controller diagramElement ifNotNil: [ :element | builder displayedRectangleOf: element ] ]
]

{ #category : 'private - applying' }
OPOntoUMLTextImport >> existingBounds [
	"The area of the top-level shapes of the diagram, or nil."

	| rectangles |
	rectangles := diagramController controllers
		              collect: [ :each | each diagramElement ]
		              thenSelect: [ :each |
			              each isNotNil and: [
				              each isEdge not and: [
					              each isRendered and: [ each owningElement == diagramController diagramElement ] ] ] ].
	rectangles := (rectangles
		               collect: [ :each | builder displayedRectangleOf: each ]
		               thenSelect: [ :each | each isNotNil ]) asArray.
	rectangles ifEmpty: [ ^ nil ].
	^ rectangles allButFirst inject: rectangles first into: [ :all :each | all merge: each ]
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> relationEndText: aReference multiplicity: aStringOrNil [

	^ (self nameOf: aReference) , (aStringOrNil
		   ifNil: [ '' ]
		   ifNotNil: [ ' [' , aStringOrNil , ']' ])
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> relationStereotypeNamed: aStringOrNil line: anInteger [
	"The palette entry of the relation ('Association' without a stereotype), or nil (and an error)."

	| names |
	aStringOrNil ifNil: [ ^ 'Association' ].
	aStringOrNil asLowercase = 'association' ifTrue: [ ^ 'Association' ].
	aStringOrNil asLowercase = 'derivation' ifTrue: [
		self addError: #'text.derivationNotSupported' with: #(  ) line: anInteger.
		^ nil ].
	names := OPOntoUMLStereotypeCatalog relationStereotypeNames select: [ :each |
		         (builder paletteEntry: each ifNone: [ nil ]) isNotNil ].
	names
		detect: [ :each | each asLowercase = aStringOrNil asLowercase ]
		ifFound: [ :found | ^ found ].
	(OPOntoUMLStereotypeCatalog classStereotypeNames anySatisfy: [ :each |
		 each asLowercase = aStringOrNil asLowercase ])
		ifTrue: [ self addError: #'text.classStereotypeForRelation' with: { aStringOrNil } line: anInteger ]
		ifFalse: [ self addUnknownStereotype: aStringOrNil among: names line: anInteger ].
	^ nil
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> resolve: aName line: anInteger [
	"The name of a class declared in the text, or a class of the diagram; nil (and an error) for an unknown name."

	(declarations keys detect: [ :each | each asLowercase = aName asLowercase ] ifNone: [ nil ])
		ifNotNil: [ :declared |
			^ (self existingClassNamed: declared) ifNil: [ declared ] ].
	(self existingClassNamed: aName) ifNotNil: [ :existing | ^ existing ].
	(invalidNames includes: aName asLowercase) ifTrue: [ ^ nil ].
	(self closestOf: declarations keys , (self existingClasses collect: [ :each | self nameOf: each ]) to: aName)
		ifNil: [ self addError: #'text.unknownClass' with: { aName } line: anInteger ]
		ifNotNil: [ :suggestion |
			self
				addError: #'text.unknownClassSuggestion'
				with: {
						aName.
						suggestion }
				line: anInteger ].
	^ nil
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> setNameOf: aFlagsArray [

	^ '{' , (aFlagsArray first
		   ifTrue: [ 'disjoint' ]
		   ifFalse: [ 'overlapping' ]) , ', ' , (aFlagsArray second
		   ifTrue: [ 'complete' ]
		   ifFalse: [ 'incomplete' ]) , '}'
]

{ #category : 'initialization' }
OPOntoUMLTextImport >> setDiagramController: aDiagramController text: aString [

	diagramController := aDiagramController.
	builder := OPDiagramBuilder on: aDiagramController.
	text := aString
]

{ #category : 'private - analysis' }
OPOntoUMLTextImport >> withoutDuplicatePairs: aCollectionOfAssociations [

	| unique |
	unique := OrderedCollection new.
	aCollectionOfAssociations do: [ :each |
		(unique anySatisfy: [ :other |
			 (self is: other key sameAs: each key) and: [ self is: other value sameAs: each value ] ])
			ifFalse: [ unique add: each ] ].
	^ unique
]
