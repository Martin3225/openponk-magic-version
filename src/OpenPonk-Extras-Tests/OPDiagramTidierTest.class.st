"
Tests of OPDiagramTidier on real diagrams opened in a workbench.
"
Class {
	#name : 'OPDiagramTidierTest',
	#superclass : 'TestCase',
	#instVars : [
		'workbench',
		'diagramController'
	],
	#category : 'OpenPonk-Extras-Tests',
	#package : 'OpenPonk-Extras-Tests'
}

{ #category : 'helpers' }
OPDiagramTidierTest >> add: aController at: aPoint [

	diagramController addAsTargetFor: aController onPosition: aPoint.
	^ aController
]

{ #category : 'helpers' }
OPDiagramTidierTest >> associationFrom: aSource to: aTarget [

	| association |
	association := OPUmlAssociationController new.
	aSource addAsSourceFor: association.
	aTarget addAsTargetFor: association.
	^ association
]

{ #category : 'helpers' }
OPDiagramTidierTest >> crossingOf: anEdgeController and: anotherEdgeController [

	| lines |
	lines := { anEdgeController. anotherEdgeController } collect: [ :edge |
		         edge roassalShape controlPoints asArray overlappingPairsCollect: [ :from :to |
			         LineSegment from: from to: to ] ].
	^ lines first anySatisfy: [ :each |
		  lines second anySatisfy: [ :other | (each intersectionWith: other) isNotNil ] ]
]

{ #category : 'helpers' }
OPDiagramTidierTest >> crossingPair [
	"A long horizontal edge crossing a short vertical one, so that going around the upper node is cheaper than the crossing."

	| a b c d |
	self openModel: (OPUMLPackage new name: 'P'; yourself).
	a := self add: OPUmlClassController new at: 0 @ 300.
	b := self add: OPUmlClassController new at: 700 @ 300.
	c := self add: OPUmlClassController new at: 350 @ 240.
	d := self add: OPUmlClassController new at: 350 @ 400.
	^ {
		  (self associationFrom: a to: b).
		  (self associationFrom: c to: d) }
]

{ #category : 'helpers' }
OPDiagramTidierTest >> openModel: aModel [

	workbench := (OPProject new
		              name: 'TidyTest';
		              addModel: aModel;
		              yourself) open.
	diagramController := workbench focusedEditor diagramController
]

{ #category : 'helpers' }
OPDiagramTidierTest >> rectangleOf: aController [

	^ aController roassalShape encompassingRectangle
]

{ #category : 'helpers' }
OPDiagramTidierTest >> segmentsOf: anEdgeController [

	^ anEdgeController roassalShape controlPoints overlappingPairsCollect: [ :from :to |
		  OPRSAnchorConstraintSegment from: from to: to ]
]

{ #category : 'running' }
OPDiagramTidierTest >> tearDown [

	workbench ifNotNil: [ workbench application closeAllWindows ].
	super tearDown
]

{ #category : 'tests' }
OPDiagramTidierTest >> testNearlyAlignedNodesAreAligned [

	| row column |
	self openModel: (OPUMLPackage new name: 'P'; yourself).
	row := { (100 @ 100). (400 @ 125). (700 @ 85) } collect: [ :each |
		       self add: OPUmlClassController new at: each ].
	column := { (100 @ 400). (130 @ 600) } collect: [ :each |
		          self add: OPUmlClassController new at: each ].

	(OPDiagramTidier on: diagramController) tidy.

	self assert: (row collect: [ :each | (self rectangleOf: each) center y ]) asSet size equals: 1.
	self assert: (column collect: [ :each | (self rectangleOf: each) center x ]) asSet size equals: 1
]

{ #category : 'tests' }
OPDiagramTidierTest >> testSpecificClassIsNotAlignedIntoTheRowOfItsGeneralClass [

	| general specific generalization |
	self openModel: (OPUMLPackage new name: 'P'; yourself).
	general := self add: OPUmlClassController new at: 100 @ 100.
	specific := self add: OPUmlClassController new at: 400 @ 130.
	generalization := OPUmlGeneralizationController new.
	specific addAsSourceFor: generalization.
	general addAsTargetFor: generalization.

	(OPDiagramTidier on: diagramController) tidy.

	self assert: (self rectangleOf: specific) center y > (self rectangleOf: general) center y
]

{ #category : 'tests' }
OPDiagramTidierTest >> testCrossingEdgeIsBentAroundAtRightAnglesInOneUndoStep [

	| edges bent |
	edges := self crossingPair.
	self assert: (self crossingOf: edges first and: edges second).

	(OPDiagramTidier on: diagramController) tidy.

	self deny: (self crossingOf: edges first and: edges second).
	bent := edges select: [ :each | each roassalShape controlPoints size > 2 ].
	self assert: bent size equals: 1.
	bent first roassalShape controlPoints overlappingPairsDo: [ :a :b |
		self assert: ((a x - b x) abs < 1 or: [ (a y - b y) abs < 1 ]) ].
	diagramController undoManager undo.
	self assert: (edges allSatisfy: [ :each | each roassalShape controlPoints size = 2 ])
]

{ #category : 'tests' }
OPDiagramTidierTest >> testNodeIsMovedWhenBendingCannotRemoveACrossing [

	| a b c d edges |
	self openModel: (OPUMLPackage new name: 'P'; yourself).
	a := self add: OPUmlClassController new at: 0 @ 0.
	b := self add: OPUmlClassController new at: 250 @ 0.
	c := self add: OPUmlClassController new at: 0 @ 200.
	d := self add: OPUmlClassController new at: 250 @ 200.
	edges := {
		         (self associationFrom: a to: d).
		         (self associationFrom: b to: c) }.
	self assert: (self crossingOf: edges first and: edges second).

	(OPDiagramTidier on: diagramController) tidy.

	self deny: (self crossingOf: edges first and: edges second).
	self assert: (edges allSatisfy: [ :each | each roassalShape controlPoints size = 2 ])
]

{ #category : 'tests' }
OPDiagramTidierTest >> testEdgesBentByTheUserAreRoutedAnew [

	| a b edge |
	self openModel: (OPUMLPackage new name: 'P'; yourself).
	a := self add: OPUmlClassController new at: 100 @ 100.
	b := self add: OPUmlClassController new at: 500 @ 100.
	edge := self associationFrom: a to: b.
	edge diagramElement innerWaypoints: { (300 @ 300) }.
	edge diagramElement updateRenderFromSelf.

	(OPDiagramTidier on: diagramController) tidy.

	self assert: edge roassalShape controlPoints size equals: 2.
	diagramController undoManager undo.
	self assert: edge roassalShape innerControlPoints asArray equals: { (300 @ 300) }
]

{ #category : 'tests' }
OPDiagramTidierTest >> testLabelsAndNodesGetOutOfTheWay [

	| a b c association label |
	self openModel: (OPUMLPackage new name: 'P'; yourself).
	a := self add: OPUmlClassController new at: 100 @ 100.
	b := self add: OPUmlClassController new at: 600 @ 100.
	c := self add: OPUmlClassController new at: 350 @ 100.
	association := OPUmlAssociationController new.
	a addAsSourceFor: association.
	b addAsTargetFor: association.
	association model name: 'executed during'.
	association modelChanged.
	self assert: ((self segmentsOf: association) anySatisfy: [ :each |
			 (each intersectRectangle: (self rectangleOf: c)) notEmpty ]).

	(OPDiagramTidier on: diagramController) tidy.

	self deny: ((self segmentsOf: association) anySatisfy: [ :each |
			 (each intersectRectangle: (self rectangleOf: c)) notEmpty ]).
	label := (association diagramElement ownedElements detect: [ :each |
		          each isKindOf: OPUmlAssociationLabel ]) roassalShape encompassingRectangle.
	self deny: ({ a. b. c } anySatisfy: [ :each | label intersects: (self rectangleOf: each) ])
]

{ #category : 'tests' }
OPDiagramTidierTest >> testNodeAnEdgePassesCloseToIsMovedClearOfIt [

	| a b c association tidier |
	self openModel: (OPUMLPackage new name: 'P'; yourself).
	a := self add: OPUmlClassController new at: 100 @ 100.
	b := self add: OPUmlClassController new at: 700 @ 500.
	c := self add: OPUmlClassController new at: 300 @ 307.
	association := OPUmlAssociationController new.
	a addAsSourceFor: association.
	b addAsTargetFor: association.
	tidier := OPDiagramTidier on: diagramController.
	self deny: ((self segmentsOf: association) anySatisfy: [ :each |
			 (each intersectRectangle: (self rectangleOf: c)) notEmpty ]).
	self assert: ((self segmentsOf: association) anySatisfy: [ :each |
			 (each intersectRectangle: ((self rectangleOf: c) expandBy: tidier edgeClearance)) notEmpty ]).

	tidier tidy.

	self deny: ((self segmentsOf: association) anySatisfy: [ :each |
			 (each intersectRectangle: ((self rectangleOf: c) expandBy: tidier edgeClearance - 1)) notEmpty ])
]

{ #category : 'tests' }
OPDiagramTidierTest >> testLabelFarFromItsEdgeIsBroughtBack [

	| a b association label anchor |
	self openModel: (OPUMLPackage new name: 'P'; yourself).
	a := self add: OPUmlClassController new at: 100 @ 100.
	b := self add: OPUmlClassController new at: 600 @ 100.
	association := OPUmlAssociationController new.
	a addAsSourceFor: association.
	b addAsTargetFor: association.
	association model name: 'drives'.
	association modelChanged.
	label := (association diagramElement ownedElements detect: [ :each |
		          each isKindOf: OPUmlAssociationLabel ]) roassalShape.
	anchor := label propertyAt: OPRSAnchorConstraint.
	anchor distanceToLine: 150.
	anchor moveShape.

	(OPDiagramTidier on: diagramController) tidy.

	self assert: anchor distanceToLine abs <= ((anchor minDistanceToLine abs max: 5) + 40)
]

{ #category : 'tests' }
OPDiagramTidierTest >> testSeparatesOverlappingNodesInOneUndoStep [

	| first second third before stackSize |
	self openModel: (OPErd new name: 'erd'; yourself).
	first := self add: OPErdEntityController new at: 100 @ 100.
	second := self add: OPErdEntityController new at: 110 @ 105.
	third := self add: OPErdEntityController new at: 400 @ 400.
	before := { first. second. third } collect: [ :each | each diagramElement bounds position ].
	stackSize := diagramController undoManager undoStack size.

	(OPDiagramTidier on: diagramController) tidy.

	self deny: ((self rectangleOf: first) intersects: (self rectangleOf: second)).
	self assert: third diagramElement bounds position equals: before third.
	self assert: diagramController undoManager undoStack size equals: stackSize + 1.
	self assert: diagramController undoManager undoStack last description equals: 'Tidy'.
	diagramController undoManager undo.
	self
		assert: ({ first. second. third } collect: [ :each | each diagramElement bounds position ])
		equals: before
]

{ #category : 'tests' }
OPDiagramTidierTest >> testTidyIsInTheLayoutMenuOfEveryDiagram [

	self assert: (OPTidyLayoutCommand inheritsFrom: OPLayoutDiagramCommand).
	self assert: (OPTidyLayoutCommand canBeExecutedInContext: nil).
	self assert: (OPTidyLayoutCommand classAnnotations anySatisfy: [ :each |
			 each isKindOf: OPDiagramMenuActivation ])
]
