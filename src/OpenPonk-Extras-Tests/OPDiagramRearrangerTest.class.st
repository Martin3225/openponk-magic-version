"
Tests of OPDiagramRearranger on real diagrams opened in a workbench.
"
Class {
	#name : 'OPDiagramRearrangerTest',
	#superclass : 'TestCase',
	#instVars : [
		'workbench',
		'diagramController'
	],
	#category : 'OpenPonk-Extras-Tests',
	#package : 'OpenPonk-Extras-Tests'
}

{ #category : 'helpers' }
OPDiagramRearrangerTest >> add: aController at: aPoint [

	diagramController addAsTargetFor: aController onPosition: aPoint.
	^ aController
]

{ #category : 'helpers' }
OPDiagramRearrangerTest >> center: aController [

	^ aController roassalShape encompassingRectangle center
]

{ #category : 'helpers' }
OPDiagramRearrangerTest >> connect: aSource to: aTarget with: anEdgeController [

	aSource addAsSourceFor: anEdgeController.
	aTarget addAsTargetFor: anEdgeController.
	^ anEdgeController
]

{ #category : 'helpers' }
OPDiagramRearrangerTest >> crossingOf: anEdgeController and: anotherEdgeController [

	| lines |
	lines := { anEdgeController. anotherEdgeController } collect: [ :edge |
		         edge roassalShape controlPoints asArray overlappingPairsCollect: [ :from :to |
			         LineSegment from: from to: to ] ].
	^ lines first anySatisfy: [ :each |
		  lines second anySatisfy: [ :other | (each intersectionWith: other) isNotNil ] ]
]

{ #category : 'running' }
OPDiagramRearrangerTest >> setUp [

	super setUp.
	workbench := (OPProject new
		              name: 'RearrangeTest';
		              addModel: (OPUMLPackage new name: 'P'; yourself);
		              yourself) open.
	diagramController := workbench focusedEditor diagramController
]

{ #category : 'running' }
OPDiagramRearrangerTest >> tearDown [

	workbench ifNotNil: [ workbench application closeAllWindows ].
	super tearDown
]

{ #category : 'tests' }
OPDiagramRearrangerTest >> testCrossingEdgesAreUntangledInOneUndoStep [

	| nodes edges before |
	nodes := { (0 @ 0). (300 @ 0). (0 @ 300). (300 @ 300) } collect: [ :each |
		         self add: OPUmlClassController new at: each ].
	edges := {
		         (self connect: nodes first to: nodes fourth with: OPUmlAssociationController new).
		         (self connect: nodes second to: nodes third with: OPUmlAssociationController new) }.
	self assert: (self crossingOf: edges first and: edges second).
	before := nodes collect: [ :each | each diagramElement bounds position ].

	(OPDiagramRearranger on: diagramController) rearrange.

	self deny: (self crossingOf: edges first and: edges second).
	self assert: diagramController undoManager undoStack last description equals: 'Rearrange'.
	diagramController undoManager undo.
	self assert: (nodes collect: [ :each | each diagramElement bounds position ]) equals: before
]

{ #category : 'tests' }
OPDiagramRearrangerTest >> testGeneralClassesEndAboveTheirSpecificOnes [

	| general specifics |
	general := self add: OPUmlClassController new at: 300 @ 600.
	specifics := { (100 @ 100). (500 @ 100) } collect: [ :each |
		             | specific |
		             specific := self add: OPUmlClassController new at: each.
		             self connect: specific to: general with: OPUmlGeneralizationController new.
		             specific ].

	(OPDiagramRearranger on: diagramController) rearrange.

	self assert: (specifics allSatisfy: [ :each | (self center: each) y > (self center: general) y ])
]
