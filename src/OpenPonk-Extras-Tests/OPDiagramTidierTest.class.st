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
