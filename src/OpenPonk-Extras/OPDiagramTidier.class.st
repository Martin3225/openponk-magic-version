"
I tidy up a diagram without rearranging it: the user's (or a layouter's) placement is kept, only what overlaps is moved.

1. Top-level nodes that overlap or are closer than #gap are pushed apart (along the axis where they overlap less). Containers (nodes with positionable nodes inside) stay where they are, boundaries are ignored.
2. A node that an edge passes through (not one of the edge's ends) is moved out of the edge's way.
3. Every non-empty edge label (association names, multiplicities, role names, generalization sets...) is tried at several places along its edge and on both sides of it, and the place where it overlaps the least with nodes, other labels and other edges wins. Labels anchored at a distance from an edge end (multiplicities) only change side and distance from the line, so that undo restores them exactly.

All changes are recorded through OPDiagramGeometrySnapshot as one undoable step, like the layouters of OpenPonk do.
"
Class {
	#name : 'OPDiagramTidier',
	#superclass : 'Object',
	#instVars : [
		'diagramController',
		'gap'
	],
	#category : 'OpenPonk-Extras-Layout',
	#package : 'OpenPonk-Extras',
	#tag : 'Layout'
}

{ #category : 'instance creation' }
OPDiagramTidier class >> on: aDiagramController [

	^ self new
		  diagramController: aDiagramController;
		  yourself
]

{ #category : 'private - labels' }
OPDiagramTidier >> balanceCandidates [

	^ #( 0.5 0.4 0.6 0.3 0.7 0.2 0.8 0.12 0.88 )
]

{ #category : 'private - labels' }
OPDiagramTidier >> candidatesFor: anAnchorConstraint [
	"Blocks that configure the anchor of a label, the preferred (closest to the default) first."

	| distances candidates |
	distances := self distanceCandidatesFor: anAnchorConstraint.
	candidates := OrderedCollection new.
	anAnchorConstraint balance
		ifNil: [
			distances do: [ :distance |
				candidates add: [ :anchor | anchor distanceToLine: distance ] ] ]
		ifNotNil: [
			self balanceCandidates do: [ :balance |
				distances do: [ :distance |
					candidates add: [ :anchor |
						anchor
							balance: balance;
							distanceToLine: distance ] ] ] ].
	^ candidates
]

{ #category : 'private - labels' }
OPDiagramTidier >> costOf: aRectangle label: aShape nodes: nodeRectangles labels: placedRectangles segments: segmentsByEdge [

	| cost |
	cost := 0.
	nodeRectangles do: [ :each |
		cost := cost + (self overlapOf: (aRectangle expandBy: 3) with: each) ].
	placedRectangles do: [ :each |
		cost := cost + (self overlapOf: (aRectangle expandBy: 2) with: each) ].
	segmentsByEdge keysAndValuesDo: [ :edgeShape :segments |
		edgeShape == (self edgeShapeOfLabel: aShape) ifFalse: [
			segments do: [ :segment |
				(segment intersectRectangle: aRectangle) ifNotEmpty: [
					cost := cost + 150 ] ] ] ].
	^ cost
]

{ #category : 'accessing' }
OPDiagramTidier >> diagramController: aDiagramController [

	diagramController := aDiagramController
]

{ #category : 'private - labels' }
OPDiagramTidier >> distanceCandidatesFor: anAnchorConstraint [

	| base |
	base := anAnchorConstraint distanceToLine abs max: 5.
	^ {
		  anAnchorConstraint distanceToLine sign >= 0
			  ifTrue: [ base ]
			  ifFalse: [ base negated ].
		  (anAnchorConstraint distanceToLine sign >= 0
			   ifTrue: [ base negated ]
			   ifFalse: [ base ]).
		  (base + 12).
		  (base + 12) negated }
]

{ #category : 'private - nodes' }
OPDiagramTidier >> edgeControllers [

	^ (diagramController controllers select: [ :each |
		   each diagramElement isNotNil and: [
			   each diagramElement isEdge and: [
				   each diagramElement isRendered and: [ each roassalShape isNotNil ] ] ] ])
		  asArray
]

{ #category : 'private - labels' }
OPDiagramTidier >> edgeLabelShapes [
	"Rendered, non-empty labels anchored to edges, the bigger ones first (they get the first pick)."

	| labels |
	labels := self edgeControllers flatCollect: [ :each |
		          each diagramElement ownedElements select: [ :element |
			          (element isKindOf: OPEdgeLabel) and: [
				          element isRendered and: [
					          (element roassalShape
						           propertyAt: OPRSAnchorConstraint
						           ifAbsent: [ nil ]) isNotNil and: [
						          element roassalShape encompassingRectangle area > 4 ] ] ] ] ].
	^ (labels collect: [ :each | each roassalShape ]) asArray sort: [ :a :b |
		  a encompassingRectangle area >= b encompassingRectangle area ]
]

{ #category : 'private - labels' }
OPDiagramTidier >> edgeShapeOfLabel: aLabelShape [

	^ aLabelShape model owningElement roassalShape
]

{ #category : 'private' }
OPDiagramTidier >> execute: aCollectionOfCommands [

	aCollectionOfCommands ifEmpty: [ ^ self ].
	diagramController undoManager
		ifNil: [ aCollectionOfCommands do: [ :each | each execute ] ]
		ifNotNil: [ :undoManager |
			undoManager inTransactionLabeled: 'Tidy' do: [
				aCollectionOfCommands do: [ :each | undoManager execute: each ] ] ]
]

{ #category : 'accessing' }
OPDiagramTidier >> gap [

	^ gap
]

{ #category : 'accessing' }
OPDiagramTidier >> gap: aNumber [

	gap := aNumber
]

{ #category : 'initialization' }
OPDiagramTidier >> initialize [

	super initialize.
	gap := 30
]

{ #category : 'private - nodes' }
OPDiagramTidier >> isContainer: aController [

	^ diagramController controllers anySatisfy: [ :each |
		  each ~~ aController and: [
			  each diagramElement isNotNil and: [
				  each diagramElement isEdge not and: [
					  each diagramElement isPositionableByUser and: [
						  each diagramElement owningElementWithPossibleController
						  == aController diagramElement ] ] ] ] ]
]

{ #category : 'private - nodes' }
OPDiagramTidier >> moveNodesOutOfEdges: movableShapes [
	"Move nodes that an edge passes through (without ending in them) to the side of the edge."

	| moved |
	moved := false.
	self edgeControllers do: [ :edgeController |
		| line ends |
		line := edgeController roassalShape.
		ends := { line from. line to }.
		movableShapes do: [ :node |
			(ends includes: node) ifFalse: [
				(self segmentsOf: line) do: [ :segment |
					(segment intersectRectangle: node encompassingRectangle) ifNotEmpty: [
						| normal side push |
						normal := segment vector normal.
						side := (node position - segment from) dotProduct: normal.
						push := normal * (side >= 0 ifTrue: [ 1 ] ifFalse: [ -1 ])
						        * ((node encompassingRectangle extent max / 2) + (gap / 2)).
						node translateBy: push rounded.
						moved := true ] ] ] ] ].
	^ moved
]

{ #category : 'private - nodes' }
OPDiagramTidier >> nodeControllers [
	"Top-level, positionable nodes; boundaries are only decoration around other nodes."

	^ (diagramController controllers select: [ :each |
		   | element |
		   element := each diagramElement.
		   element isNotNil and: [
			   element isEdge not and: [
				   element isRendered and: [
					   element isPositionableByUser and: [
						   (element isKindOf: OPBoundary) not and: [
							   element owningElement == diagramController diagramElement ] ] ] ] ] ])
		  asArray
]

{ #category : 'private' }
OPDiagramTidier >> overlapOf: aRectangle with: anotherRectangle [

	(aRectangle intersects: anotherRectangle) ifFalse: [ ^ 0 ].
	^ (aRectangle intersect: anotherRectangle) area
]

{ #category : 'private - labels' }
OPDiagramTidier >> placeLabels: labelShapes avoiding: nodeShapes [

	| nodeRectangles placed segmentsByEdge |
	nodeRectangles := nodeShapes collect: [ :each | each encompassingRectangle ].
	segmentsByEdge := IdentityDictionary new.
	self edgeControllers do: [ :each |
		segmentsByEdge at: each roassalShape put: (self segmentsOf: each roassalShape) ].
	placed := OrderedCollection new.
	labelShapes do: [ :shape |
		| anchor best bestCost |
		anchor := shape propertyAt: OPRSAnchorConstraint.
		bestCost := nil.
		(self candidatesFor: anchor) doWithIndex: [ :candidate :index |
			| cost |
			candidate value: anchor.
			anchor moveShape.
			cost := (self
				         costOf: shape encompassingRectangle
				         label: shape
				         nodes: nodeRectangles
				         labels: placed
				         segments: segmentsByEdge) + index.
			(bestCost isNil or: [ cost < bestCost ]) ifTrue: [
				bestCost := cost.
				best := candidate ] ].
		best value: anchor.
		anchor moveShape.
		placed add: shape encompassingRectangle ]
]

{ #category : 'private' }
OPDiagramTidier >> segmentsOf: aLine [

	^ aLine controlPoints overlappingPairsCollect: [ :from :to |
		  OPRSAnchorConstraintSegment from: from to: to ]
]

{ #category : 'private - nodes' }
OPDiagramTidier >> separate: movableShapes from: fixedShapes [
	"Push apart nodes closer than the gap; answer whether anything moved."

	| moved all |
	moved := false.
	all := movableShapes , fixedShapes.
	1 to: all size do: [ :i |
		i + 1 to: all size do: [ :j |
			| a b ra rb dx dy aMoves bMoves |
			a := all at: i.
			b := all at: j.
			aMoves := i <= movableShapes size.
			bMoves := j <= movableShapes size.
			(aMoves or: [ bMoves ]) ifTrue: [
				ra := a encompassingRectangle expandBy: gap / 2.
				rb := b encompassingRectangle expandBy: gap / 2.
				dx := (ra right min: rb right) - (ra left max: rb left).
				dy := (ra bottom min: rb bottom) - (ra top max: rb top).
				(dx > 0 and: [ dy > 0 ]) ifTrue: [
					| push |
					push := dx <= dy
						        ifTrue: [
							        (a position x <= b position x
								         ifTrue: [ dx ]
								         ifFalse: [ dx negated ]) @ 0 ]
						        ifFalse: [
							        0 @ (a position y <= b position y
								         ifTrue: [ dy ]
								         ifFalse: [ dy negated ]) ].
					(aMoves and: [ bMoves ])
						ifTrue: [
							a translateBy: (push / 2) negated ceiling.
							b translateBy: (push / 2) ceiling ]
						ifFalse: [
							aMoves
								ifTrue: [ a translateBy: push negated ]
								ifFalse: [ b translateBy: push ] ].
					moved := true ] ] ] ].
	^ moved
]

{ #category : 'tidying' }
OPDiagramTidier >> tidy [

	| nodes movable fixed labels snapshot passes |
	nodes := self nodeControllers.
	movable := (nodes reject: [ :each | self isContainer: each ]) collect: [ :each |
		           each roassalShape ].
	fixed := (nodes select: [ :each | self isContainer: each ]) collect: [ :each |
		         each roassalShape ].
	labels := self edgeLabelShapes.
	snapshot := OPDiagramGeometrySnapshot onNodes: movable , labels.
	passes := 0.
	[ (self separate: movable from: fixed) and: [ (passes := passes + 1) < 200 ] ] whileTrue.
	2 timesRepeat: [
		(self moveNodesOutOfEdges: movable) ifTrue: [
			passes := 0.
			[ (self separate: movable from: fixed) and: [ (passes := passes + 1) < 200 ] ]
				whileTrue ] ].
	self placeLabels: self edgeLabelShapes avoiding: movable , fixed.
	self execute: snapshot deltaCommands.
	diagramController updateCanvas
]
