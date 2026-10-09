"
I tidy up a diagram without rearranging it: the user's (or a layouter's) placement is kept, only what overlaps is moved.

0. Nodes whose centers are within #alignTolerance of each other across a row (or a column) are snapped onto one row (column), at the median of the group. A specific class is never put into the row of its general class.
1. Top-level nodes that overlap or are closer than #gap are pushed apart (along the axis where they overlap less). Containers (nodes with positionable nodes inside) stay where they are, boundaries are ignored.
2. A node that an edge passes through or near (closer than #edgeClearance, not one of the edge's ends) is moved just far enough to the side of the edge. Steps 1 and 2 repeat, as moving a node also moves its own edges.
3. Edges are routed anew: bends (also the user's) are removed from every edge between two different nodes, then a straight edge that crosses other edges gets bends around the obstacles, if the way around costs less than #crossingCost per crossing it saves and passes no node. Right-angled routes (an L, or a Z or U along a channel next to a node grown by #gap) are preferred; slanted segments cost #diagonalCost.
   If crossings remain, nodes are moved or swapped where that removes crossings (#moveCost per pixel moved, keeping #gap and #edgeClearance), the nodes are separated again and edges bent again. This result is kept only if it has fewer crossings than bending alone.
4. Every non-empty edge label (association names, multiplicities, role names, generalization sets...) is tried at several places along its edge and on both sides of it, and the place where it overlaps the least with nodes, other labels and other edges wins. Labels anchored at a distance from an edge end (multiplicities) only change side and distance from the line, so that undo restores them exactly.

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

{ #category : 'private - nodes' }
OPDiagramTidier >> align: nodeShapes along: aSymbol except: generalizationPairs [
	"Snap the centers of nodes that lie within #alignTolerance of the first node of their group (sorted by the coordinate aSymbol, #x or #y) to the median of the group. A specific class and its general class are never put into one group."

	| groups |
	groups := OrderedCollection new.
	(nodeShapes asArray sorted: [ :a :b |
		 (a encompassingRectangle center perform: aSymbol) <= (b encompassingRectangle center perform: aSymbol) ])
		do: [ :node |
			| value group |
			value := node encompassingRectangle center perform: aSymbol.
			group := groups ifNotEmpty: [ groups last ] ifEmpty: [ nil ].
			(group notNil and: [
				 value - (group first encompassingRectangle center perform: aSymbol) <= self alignTolerance and: [
					 group noneSatisfy: [ :each |
						 (generalizationPairs includes: { each. node }) or: [
							 generalizationPairs includes: { node. each } ] ] ] ])
				ifTrue: [ group add: node ]
				ifFalse: [ groups add: (OrderedCollection with: node) ] ].
	groups do: [ :group |
		group size > 1 ifTrue: [
			| target |
			target := (group at: group size + 1 // 2) encompassingRectangle center perform: aSymbol.
			group do: [ :each |
				| delta |
				delta := (target - (each encompassingRectangle center perform: aSymbol)) rounded.
				delta = 0 ifFalse: [
					each translateBy: (aSymbol = #x
							 ifTrue: [ delta @ 0 ]
							 ifFalse: [ 0 @ delta ]) ] ] ] ]
]

{ #category : 'private - nodes' }
OPDiagramTidier >> alignNodes: movableShapes [
	"Put nodes that almost share a row onto one row, and nodes that almost share a column into one column."

	| generalizationPairs |
	generalizationPairs := (self edgeControllers
		                        select: [ :each | self isGeneralization: each ]
		                        thenCollect: [ :each | { each roassalShape from. each roassalShape to } ]) asSet.
	self align: movableShapes along: #y except: generalizationPairs.
	"A specific class right under its general one is welcome."
	self align: movableShapes along: #x except: #(  )
]

{ #category : 'private - nodes' }
OPDiagramTidier >> alignTolerance [
	"Nodes whose centers are at most this far apart (across a row or a column) get aligned."

	^ 40
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
	"Distances from the line, nearest first, the current side before the other one. They grow from the label's default distance (#minDistanceToLine), not from the current one, so that repeated tidying does not drift labels away from their edges."

	| base side |
	base := anAnchorConstraint minDistanceToLine abs max: 5.
	side := anAnchorConstraint distanceToLine sign >= 0
		        ifTrue: [ 1 ]
		        ifFalse: [ -1 ].
	^ #( 0 12 24 40 ) flatCollect: [ :extra |
		  {
			  (base + extra * side).
			  (base + extra * side negated) } ]
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
OPDiagramTidier >> execute: aCollectionOfCommands labeled: anUndoLabel [

	aCollectionOfCommands ifEmpty: [ ^ self ].
	diagramController undoManager
		ifNil: [ aCollectionOfCommands do: [ :each | each execute ] ]
		ifNotNil: [ :undoManager |
			undoManager inTransactionLabeled: anUndoLabel do: [
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
OPDiagramTidier >> edgeClearance [
	"How far an edge must stay from a node it does not end in."

	^ gap / 2
]

{ #category : 'private - nodes' }
OPDiagramTidier >> moveNodesOutOfEdges: movableShapes [
	"Move nodes that an edge passes through or closer than #edgeClearance (without ending in them) to the side of the edge, just enough to clear it."

	| moved |
	moved := false.
	self edgeControllers do: [ :edgeController |
		| line ends |
		line := edgeController roassalShape.
		ends := { line from. line to }.
		movableShapes do: [ :node |
			(ends includes: node) ifFalse: [
				(self segmentsOf: line) do: [ :segment |
					| rectangle |
					rectangle := node encompassingRectangle expandBy: self edgeClearance.
					(segment intersectRectangle: rectangle) ifNotEmpty: [
						| normal side reach push |
						normal := segment vector normal.
						side := (rectangle center - segment from) dotProduct: normal.
						"Distance from the center to the farthest corner (of the rectangle grown by the clearance) across the line."
						reach := (rectangle width * normal x) abs + (rectangle height * normal y) abs / 2 + 1.
						push := normal * (side >= 0
							         ifTrue: [ reach - side ]
							         ifFalse: [ (reach + side) negated ]).
						node translateBy: (push x abs ceiling * push x sign) @ (push y abs ceiling * push y sign).
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

{ #category : 'private - nodes' }
OPDiagramTidier >> separateAll: movableShapes from: fixedShapes [

	| passes |
	passes := 0.
	[ (self separate: movableShapes from: fixedShapes) and: [ (passes := passes + 1) < 200 ] ]
		whileTrue
]

{ #category : 'private - nodes' }
OPDiagramTidier >> separateAndClear: movableShapes from: fixedShapes [
	"Push nodes apart and out of edges. Moving a node out of an edge moves its own edges and can push it into another node, so repeat until both hold (separation has the last word)."

	| rounds |
	self separateAll: movableShapes from: fixedShapes.
	rounds := 0.
	[
	(self moveNodesOutOfEdges: movableShapes) and: [
		self separateAll: movableShapes from: fixedShapes.
		(rounds := rounds + 1) < 10 ] ] whileTrue
]

{ #category : 'private - crossings' }
OPDiagramTidier >> candidatePlacementsOf: aNode in: rectangles neighbors: neighborNodes movable: movableNodes [
	"Moves to try, each a collection of node -> new center: steps of one or two node sizes, places right next to a neighbor (a node it shares an edge with) and swaps with another movable node."

	| rectangle center width height placements |
	rectangle := rectangles at: aNode.
	center := rectangle center.
	width := rectangle width.
	height := rectangle height.
	placements := OrderedCollection new.
	-2 to: 2 do: [ :i |
		-2 to: 2 do: [ :j |
			(i = 0 and: [ j = 0 ]) ifFalse: [
				placements add: { (aNode -> (center + ((width + gap * i) @ (height + gap * j)))) } ] ] ].
	neighborNodes do: [ :each |
		| other |
		other := rectangles at: each.
		placements
			add: { (aNode -> ((other left - gap - (width / 2)) @ other center y)) };
			add: { (aNode -> ((other right + gap + (width / 2)) @ other center y)) };
			add: { (aNode -> (other center x @ (other top - gap - (height / 2)))) };
			add: { (aNode -> (other center x @ (other bottom + gap + (height / 2)))) } ].
	movableNodes do: [ :each |
		each == aNode ifFalse: [
			placements add: {
					(aNode -> (rectangles at: each) center).
					(each -> center) } ] ].
	^ placements
]

{ #category : 'private - crossings' }
OPDiagramTidier >> crossingsAmong: someEdges with: allEdges in: rectangles [
	"Crossings of someEdges with allEdges, each pair counted once. Edges are triples of their end nodes and inner points."

	| indexes total |
	indexes := IdentityDictionary new.
	someEdges doWithIndex: [ :each :i | indexes at: each put: i ].
	total := 0.
	someEdges doWithIndex: [ :edge :i |
		allEdges do: [ :other |
			((indexes at: other ifAbsent: [ i + 1 ]) > i) ifTrue: [
				total := total + (self crossingsOf: edge with: other in: rectangles) ] ] ].
	^ total
]

{ #category : 'private - crossings' }
OPDiagramTidier >> crossingsOf: anEdge with: anotherEdge in: rectangles [
	"Crossings of two edges between the centers of their nodes. A crossing inside one of their end nodes is hidden by it (and edges sharing a node meet there)."

	| ends count others |
	ends := { anEdge first. anEdge second. anotherEdge first. anotherEdge second } collect: [ :each |
		        rectangles at: each ].
	others := self pointsOf: anotherEdge in: rectangles.
	count := 0.
	(self pointsOf: anEdge in: rectangles) overlappingPairsDo: [ :p1 :p2 |
		others overlappingPairsDo: [ :q1 :q2 |
			(self intersectionOf: p1 to: p2 with: q1 to: q2) ifNotNil: [ :point |
				(ends anySatisfy: [ :each | each containsPoint: point ]) ifFalse: [ count := count + 1 ] ] ] ].
	^ count
]

{ #category : 'private - crossings' }
OPDiagramTidier >> isPlacementOf: movedNodes validIn: rectangles edges: edges incident: incidentEdges [
	"Moved nodes keep #gap from other nodes, no edge passes closer than #edgeClearance to a node it does not end in, and specific classes that were below their general ones stay below."

	movedNodes do: [ :node |
		| grown |
		grown := (rectangles at: node) expandBy: gap - 1.
		rectangles keysAndValuesDo: [ :other :rectangle |
			(other ~~ node and: [ grown intersects: rectangle ]) ifTrue: [ ^ false ] ].
		grown := (rectangles at: node) expandBy: self edgeClearance.
		edges do: [ :edge |
			(edge first ~~ node and: [
				 edge second ~~ node and: [ self points: (self pointsOf: edge in: rectangles) hit: grown ] ])
				ifTrue: [ ^ false ] ].
		(incidentEdges at: node) do: [ :edge |
			(edge fourth and: [
				 (rectangles at: edge first) center y <= (rectangles at: edge second) center y ]) ifTrue: [
				^ false ] ].
		(incidentEdges at: node) do: [ :edge |
			| points |
			points := self pointsOf: edge in: rectangles.
			rectangles keysAndValuesDo: [ :other :rectangle |
				(other ~~ edge first and: [
					 other ~~ edge second and: [
						 self points: points hit: (rectangle expandBy: self edgeClearance) ] ]) ifTrue: [
					^ false ] ] ] ].
	^ true
]

{ #category : 'private - crossings' }
OPDiagramTidier >> isGeneralization: anEdgeController [
	"Whether the edge goes from a specific class (its source) to a general one."

	^ (Smalltalk at: #OPUMLGeneralization ifAbsent: [ nil ])
		  ifNil: [ false ]
		  ifNotNil: [ :generalization | anEdgeController model isKindOf: generalization ]
]

{ #category : 'private - crossings' }
OPDiagramTidier >> moveCost [
	"Cost of moving a node by one pixel when looking for fewer crossings, against #crossingCost per crossing."

	^ 1
]

{ #category : 'private - crossings' }
OPDiagramTidier >> points: routePoints hit: aRectangle [

	routePoints overlappingPairsDo: [ :from :to |
		((OPRSAnchorConstraintSegment from: from to: to) intersectRectangle: aRectangle) ifNotEmpty: [
			^ true ] ].
	^ false
]

{ #category : 'private - crossings' }
OPDiagramTidier >> pointsOf: anEdge in: rectangles [

	^ { (rectangles at: anEdge first) center } , anEdge third
	  , { (rectangles at: anEdge second) center }
]

{ #category : 'private - crossings' }
OPDiagramTidier >> reduceCrossingsMoving: movableShapes among: nodeShapes [
	"Move or swap nodes where it removes edge crossings, for a cost of #moveCost per pixel moved. The search runs on rectangles; the nodes are moved at the end. Answer whether any moved."

	| rectangles start edges incident neighbors movable passes improved moved |
	rectangles := IdentityDictionary new.
	nodeShapes do: [ :each | rectangles at: each put: each encompassingRectangle ].
	start := IdentityDictionary new.
	movableShapes do: [ :each | start at: each put: each encompassingRectangle center ].
	edges := OrderedCollection new.
	self edgeControllers do: [ :each |
		| line points |
		line := each roassalShape.
		points := line controlPoints asArray.
		(line from ~~ line to and: [
			 (rectangles includesKey: line from) and: [ rectangles includesKey: line to ] ]) ifTrue: [
			edges add: {
					line from.
					line to.
					(points copyFrom: 2 to: points size - 1).
					((self isGeneralization: each) and: [
						 line from encompassingRectangle center y > line to encompassingRectangle center y ]) } ] ].
	incident := IdentityDictionary new.
	neighbors := IdentityDictionary new.
	nodeShapes do: [ :each |
		incident at: each put: OrderedCollection new.
		neighbors at: each put: IdentitySet new ].
	edges do: [ :each |
		(incident at: each first) add: each.
		(incident at: each second) add: each.
		(neighbors at: each first) add: each second.
		(neighbors at: each second) add: each first ].
	movable := movableShapes select: [ :each | (incident at: each) notEmpty ].
	passes := 0.
	[
	improved := false.
	movable do: [ :node |
		(self
			 improvePlacementOf: node
			 in: rectangles
			 start: start
			 edges: edges
			 incident: incident
			 neighbors: (neighbors at: node)
			 movable: movableShapes) ifTrue: [ improved := true ] ].
	improved and: [ (passes := passes + 1) < 4 ] ] whileTrue.
	moved := false.
	movableShapes do: [ :each |
		| delta |
		delta := (rectangles at: each) center - each encompassingRectangle center.
		delta = (0 @ 0) ifFalse: [
			each translateBy: delta.
			moved := true ] ].
	^ moved
]

{ #category : 'private - crossings' }
OPDiagramTidier >> improvePlacementOf: aNode in: rectangles start: start edges: edges incident: incident neighbors: neighborNodes movable: movableNodes [
	"Apply the best candidate placement of aNode (and of the node it swaps with) that has fewer crossings and pays for its move; answer whether there was one."

	| best bestGain alone |
	best := nil.
	bestGain := 0.
	alone := self crossingsAmong: (incident at: aNode) with: edges in: rectangles.
	(self candidatePlacementsOf: aNode in: rectangles neighbors: neighborNodes movable: movableNodes) do: [ :placement |
		| moved affected before after old movePrice |
		moved := placement collect: [ :each | each key ].
		affected := moved size = 1
			            ifTrue: [ incident at: aNode ]
			            ifFalse: [ (moved flatCollect: [ :each | incident at: each ]) asIdentitySet asArray ].
		before := moved size = 1
			          ifTrue: [ alone ]
			          ifFalse: [ self crossingsAmong: affected with: edges in: rectangles ].
		movePrice := (placement inject: 0 into: [ :sum :each |
			              sum + (each value distanceTo: (start at: each key))
			              - ((rectangles at: each key) center distanceTo: (start at: each key)) ])
		             * self moveCost.
		before * self crossingCost - movePrice > bestGain ifTrue: [
			old := moved collect: [ :each | each -> (rectangles at: each) ].
			placement do: [ :each |
				rectangles at: each key put: (Rectangle center: each value extent: (rectangles at: each key) extent) ].
			((self isPlacementOf: moved validIn: rectangles edges: edges incident: incident) and: [
				 (after := self crossingsAmong: affected with: edges in: rectangles) < before ]) ifTrue: [
				| gain |
				gain := before - after * self crossingCost - movePrice.
				gain > bestGain ifTrue: [
					bestGain := gain.
					best := placement collect: [ :each | each key -> (rectangles at: each key) ] ] ].
			old do: [ :each | rectangles at: each key put: each value ] ] ].
	best ifNil: [ ^ false ].
	best do: [ :each | rectangles at: each key put: each value ].
	^ true
]

{ #category : 'private - edges' }
OPDiagramTidier >> bend: anEdgeController avoiding: nodeShapes [
	"Bend the edge where a way around has a lower cost than its crossings (on its shape only, see #waypointCommandsSince:); answer whether it was bent."

	| line obstacles straight straightLength bestCost best |
	line := anEdgeController roassalShape.
	obstacles := self obstaclesFor: line.
	straight := self routeOf: line through: #(  ).
	straightLength := self lengthOf: straight.
	bestCost := (self crossingsOf: straight of: line obstacles: obstacles) * self crossingCost.
	bestCost = 0 ifTrue: [ ^ false ].
	best := nil.
	(self bendCandidatesFor: line among: nodeShapes) do: [ :inner |
		| route cost |
		route := self routeOf: line through: inner.
		cost := (self lengthOf: route) - straightLength + (inner size * self bendCost)
		        + ((self diagonalSegmentsOf: route) * self diagonalCost).
		(cost < bestCost and: [ (self route: route hitsNodes: nodeShapes of: line) not ]) ifTrue: [
			cost := cost + ((self crossingsOf: route of: line obstacles: obstacles) * self crossingCost).
			cost < bestCost ifTrue: [
				bestCost := cost.
				best := inner ] ] ].
	best ifNil: [ ^ false ].
	"Not rounded: node centers can lie on half pixels and a rounded bend would slant the line next to it."
	line innerControlPoints: best asArray.
	line update.
	^ true
]

{ #category : 'private - edges' }
OPDiagramTidier >> reroutableEdgesAmong: endShapes [
	"Edges between two different nodes of endShapes; self-loops need their bends to be seen."

	^ self edgeControllers select: [ :each |
		  | line |
		  line := each roassalShape.
		  line from ~~ line to and: [ (endShapes includes: line from) and: [ endShapes includes: line to ] ] ]
]

{ #category : 'private - edges' }
OPDiagramTidier >> straightenEdgesAmong: endShapes [
	"Remove all bends (also the user's) from edges Tidy routes, so that they are routed anew."

	(self reroutableEdgesAmong: endShapes asIdentitySet) do: [ :each |
		| line |
		line := each roassalShape.
		line controlPoints size > 2 ifTrue: [
			line innerControlPoints: #(  ).
			line update ] ]
]

{ #category : 'private - edges' }
OPDiagramTidier >> waypointsOfEdges [
	"Edge controllers with their waypoints (as stored in their diagram elements) and the inner points of their shapes."

	^ self edgeControllers collect: [ :each |
		  {
			  each.
			  each diagramElement waypoints copy.
			  each roassalShape innerControlPoints asArray } ]
]

{ #category : 'private - edges' }
OPDiagramTidier >> waypointCommandsSince: initialWaypoints [
	"Undoable commands storing the bends of every edge whose shape got other bends than it had (see #waypointsOfEdges)."

	^ initialWaypoints
		  select: [ :each | each first roassalShape innerControlPoints asArray ~= each third ]
		  thenCollect: [ :each |
			  OPModifyEdgeWaypointsCommand
				  edge: each first diagramElement
				  oldWaypoints: each second
				  newWaypoints: each first roassalShape controlPoints copy ]
]

{ #category : 'private - edges' }
OPDiagramTidier >> bendCandidatesFor: aLine among: nodeShapes [
	"Inner waypoints to try. Right-angled routes: an L through the corner between the ends, and a Z or U running horizontally from one end and vertically along a channel next to a node grown by the gap (or vertically and then horizontally). Then routes with slanted segments: one bend at a corner of a grown node, and two bends at pairs of the corners nearest to the straight line (#diagonalCost makes them the last resort)."

	| from to ends grown xs ys corners nearest candidates |
	from := aLine from encompassingRectangle center.
	to := aLine to encompassingRectangle center.
	ends := { aLine from. aLine to } collect: [ :each | each encompassingRectangle expandBy: 2 ].
	grown := nodeShapes collect: [ :each | each encompassingRectangle expandBy: gap ].
	xs := (grown flatCollect: [ :each | { each left. each right } ]) asSet.
	ys := (grown flatCollect: [ :each | { each top. each bottom } ]) asSet.
	xs add: from x + to x / 2.
	ys add: from y + to y / 2.
	candidates := OrderedCollection new.
	candidates
		add: { (from x @ to y) };
		add: { (to x @ from y) }.
	xs do: [ :x |
		candidates add: {
				(x @ from y).
				(x @ to y) } ].
	ys do: [ :y |
		candidates add: {
				(from x @ y).
				(to x @ y) } ].
	corners := grown flatCollect: [ :each | each corners ].
	corners do: [ :each | candidates add: { each } ].
	nearest := ((corners collect: [ :each |
		             (self distanceOf: each toSegmentFrom: from to: to) -> each ]) asArray sort: [
		            :a
		            :b | a key <= b key ]) first: (16 min: corners size).
	nearest do: [ :a |
		nearest do: [ :b | a == b ifFalse: [ candidates add: { a value. b value } ] ] ].
	"A bend inside an end node would make the edge start or end in a zero-length stub."
	^ candidates reject: [ :inner |
		  inner anySatisfy: [ :point | ends anySatisfy: [ :each | each containsPoint: point ] ] ]
]

{ #category : 'private - edges' }
OPDiagramTidier >> bendCost [
	"Cost of one bend, in pixels of extra length."

	^ 20
]

{ #category : 'private - edges' }
OPDiagramTidier >> borderPointOf: aShape toward: aPoint [
	"Where a straight line from the center of aShape towards aPoint leaves its rectangle."

	| rectangle center delta t |
	rectangle := aShape encompassingRectangle.
	center := rectangle center.
	delta := aPoint - center.
	t := 1.
	delta x = 0 ifFalse: [ t := t min: rectangle width / 2 / delta x abs ].
	delta y = 0 ifFalse: [ t := t min: rectangle height / 2 / delta y abs ].
	^ center + (delta * t)
]

{ #category : 'private - edges' }
OPDiagramTidier >> crossingCost [
	"Cost of crossing another edge, in pixels of extra length: an edge takes a way around when it is shorter than this per crossing it saves."

	^ 400
]

{ #category : 'private - edges' }
OPDiagramTidier >> crossingsOf: routePoints of: aLine obstacles: obstacles [
	"Count where the route crosses the other edges (obstacles are pairs of a line and its points). Edges that share an end node with aLine meet there, which is not a crossing."

	| count |
	count := 0.
	obstacles do: [ :obstacle |
		| other shared |
		other := obstacle first.
		shared := ({ other from. other to } select: [ :each |
			           each == aLine from or: [ each == aLine to ] ]) collect: [ :each |
			          each encompassingRectangle expandBy: 5 ].
		routePoints overlappingPairsDo: [ :p1 :p2 |
			obstacle second overlappingPairsDo: [ :q1 :q2 |
				(self intersectionOf: p1 to: p2 with: q1 to: q2) ifNotNil: [ :point |
					(shared anySatisfy: [ :each | each containsPoint: point ]) ifFalse: [
						count := count + 1 ] ] ] ] ].
	^ count
]

{ #category : 'private - edges' }
OPDiagramTidier >> distanceOf: aPoint toSegmentFrom: a to: b [

	| ab lengthSquared t |
	ab := b - a.
	lengthSquared := ab dotProduct: ab.
	t := lengthSquared = 0
		     ifTrue: [ 0 ]
		     ifFalse: [ (((aPoint - a) dotProduct: ab) / lengthSquared max: 0) min: 1 ].
	^ aPoint distanceTo: a + (ab * t)
]

{ #category : 'private - edges' }
OPDiagramTidier >> diagonalCost [
	"Cost of a slanted segment in a bent edge, in pixels of extra length: right angles are preferred."

	^ 150
]

{ #category : 'private - edges' }
OPDiagramTidier >> diagonalSegmentsOf: routePoints [

	| count |
	count := 0.
	routePoints overlappingPairsDo: [ :a :b |
		((a x - b x) abs >= 1 and: [ (a y - b y) abs >= 1 ]) ifTrue: [ count := count + 1 ] ].
	^ count
]

{ #category : 'private - edges' }
OPDiagramTidier >> intersectionOf: p1 to: p2 with: q1 to: q2 [
	"The point where two segments cross, or nil. Segments running along each other (parallel and less than 3 pixels apart) meet in the middle of their common part."

	| r s qp denominator lengthSquared t u |
	((p1 x max: p2 x) + 3 < (q1 x min: q2 x) or: [
		 (q1 x max: q2 x) + 3 < (p1 x min: p2 x) or: [
			 (p1 y max: p2 y) + 3 < (q1 y min: q2 y) or: [ (q1 y max: q2 y) + 3 < (p1 y min: p2 y) ] ] ])
		ifTrue: [ ^ nil ].
	r := p2 - p1.
	s := q2 - q1.
	qp := q1 - p1.
	lengthSquared := r dotProduct: r.
	(lengthSquared = 0 or: [ (s dotProduct: s) = 0 ]) ifTrue: [ ^ nil ].
	denominator := r x * s y - (r y * s x).
	denominator abs < (1.0e-3 * (lengthSquared * (s dotProduct: s)) sqrt) ifTrue: [
		| t0 t1 low high |
		(qp x * r y - (qp y * r x)) abs / lengthSquared sqrt >= 3 ifTrue: [ ^ nil ].
		t0 := (qp dotProduct: r) / lengthSquared.
		t1 := (q2 - p1 dotProduct: r) / lengthSquared.
		low := (t0 min: t1) max: 0.
		high := (t0 max: t1) min: 1.
		low < high ifFalse: [ ^ nil ].
		^ p1 + (r * (low + high / 2)) ].
	t := qp x * s y - (qp y * s x) / denominator.
	u := qp x * r y - (qp y * r x) / denominator.
	((t between: 0 and: 1) and: [ u between: 0 and: 1 ]) ifFalse: [ ^ nil ].
	^ p1 + (r * t)
]

{ #category : 'private - edges' }
OPDiagramTidier >> lengthOf: routePoints [

	| length |
	length := 0.
	routePoints overlappingPairsDo: [ :a :b | length := length + (a distanceTo: b) ].
	^ length
]

{ #category : 'private - edges' }
OPDiagramTidier >> obstaclesFor: aLine [
	"The other edges with their points."

	^ (self edgeControllers
		   collect: [ :each | each roassalShape ]
		   thenSelect: [ :each | each ~~ aLine ]) collect: [ :each |
		  {
			  each.
			  each controlPoints asArray } ]
]

{ #category : 'private - edges' }
OPDiagramTidier >> route: routePoints hitsNodes: nodeShapes of: aLine [
	"Whether a segment of the route passes through or closer than #edgeClearance to a node. The edge's own ends only count for segments that do not start or end in them."

	| last |
	last := routePoints size - 1.
	1 to: last do: [ :i |
		| segment |
		segment := OPRSAnchorConstraintSegment from: (routePoints at: i) to: (routePoints at: i + 1).
		nodeShapes do: [ :node |
			((i = 1 and: [ node == aLine from ]) or: [ i = last and: [ node == aLine to ] ]) ifFalse: [
				(segment intersectRectangle: (node encompassingRectangle expandBy: self edgeClearance))
					ifNotEmpty: [ ^ true ] ] ] ].
	^ false
]

{ #category : 'private - edges' }
OPDiagramTidier >> routeEdgesAround: nodeShapes [
	"Bend straight edges that cross other edges around the obstacles where a way around is short enough (see #crossingCost). Only the shapes change."

	| ends rounds bentAny |
	ends := nodeShapes asIdentitySet.
	rounds := 0.
	[
	bentAny := false.
	(self straightCrossingEdgesBetween: ends) do: [ :each |
		(self bend: each avoiding: nodeShapes) ifTrue: [ bentAny := true ] ].
	bentAny and: [ (rounds := rounds + 1) < 3 ] ] whileTrue
]

{ #category : 'private - edges' }
OPDiagramTidier >> routeOf: aLine through: innerPoints [
	"The points of the edge if it went through innerPoints, its ends on the borders of its nodes."

	| first last |
	first := innerPoints
		         ifEmpty: [ aLine to encompassingRectangle center ]
		         ifNotEmpty: [ innerPoints first ].
	last := innerPoints
		        ifEmpty: [ aLine from encompassingRectangle center ]
		        ifNotEmpty: [ innerPoints last ].
	^ { (self borderPointOf: aLine from toward: first) } , innerPoints asArray
	  , { (self borderPointOf: aLine to toward: last) }
]

{ #category : 'private - edges' }
OPDiagramTidier >> straightCrossingEdgesBetween: endShapes [
	"Edges without bends between two of endShapes that cross another edge, the most crossings first."

	| counted |
	counted := OrderedCollection new.
	self edgeControllers do: [ :each |
		| line |
		line := each roassalShape.
		(line controlPoints size <= 2 and: [
			 line from ~~ line to and: [ (endShapes includes: line from) and: [ endShapes includes: line to ] ] ])
			ifTrue: [
				| crossings |
				crossings := self
					             crossingsOf: line controlPoints asArray
					             of: line
					             obstacles: (self obstaclesFor: line).
				crossings > 0 ifTrue: [ counted add: crossings -> each ] ] ].
	^ (counted asArray sort: [ :a :b | a key >= b key ]) collect: [ :each | each value ]
]

{ #category : 'private - crossings' }
OPDiagramTidier >> totalCrossings [
	"Crossings of the edges as drawn now (each counted from both edges)."

	^ self edgeControllers inject: 0 into: [ :sum :each |
		  | line |
		  line := each roassalShape.
		  sum + (self
			   crossingsOf: line controlPoints asArray
			   of: line
			   obstacles: (self obstaclesFor: line)) ]
]

{ #category : 'tidying' }
OPDiagramTidier >> tidy [

	self tidyLabeled: 'Tidy' after: [ :movableShapes :fixedShapes |  ]
]

{ #category : 'tidying' }
OPDiagramTidier >> tidyLabeled: anUndoLabel after: aBlock [
	"Tidy up after aBlock has placed the nodes (it gets the movable and the fixed node shapes and moves the shapes only); all of it is one undoable step named anUndoLabel."

	| nodes movable fixed all labels snapshot waypoints |
	nodes := self nodeControllers.
	movable := (nodes reject: [ :each | self isContainer: each ]) collect: [ :each |
		           each roassalShape ].
	fixed := (nodes select: [ :each | self isContainer: each ]) collect: [ :each |
		         each roassalShape ].
	all := movable , fixed.
	labels := self edgeLabelShapes.
	snapshot := OPDiagramGeometrySnapshot onNodes: movable , labels.
	waypoints := self waypointsOfEdges.
	self straightenEdgesAmong: all.
	aBlock value: movable value: fixed.
	self alignNodes: movable.
	self separateAndClear: movable from: fixed.
	self routeEdgesAround: all.
	"Moving nodes changes the layout more than bending edges, so it is kept only when it ends with fewer crossings."
	self totalCrossings > 0 ifTrue: [
		| crossings centers |
		crossings := self totalCrossings.
		self straightenEdgesAmong: all.
		centers := movable collect: [ :each | each -> each encompassingRectangle center ].
		(self reduceCrossingsMoving: movable among: all) ifTrue: [
			self separateAndClear: movable from: fixed.
			self routeEdgesAround: all.
			self totalCrossings < crossings ifFalse: [
				self straightenEdgesAmong: all.
				centers do: [ :each |
					each key translateBy: each value - each key encompassingRectangle center ] ] ].
		self totalCrossings < crossings ifFalse: [
			self straightenEdgesAmong: all.
			self routeEdgesAround: all ] ].
	self placeLabels: self edgeLabelShapes avoiding: movable , fixed.
	self
		execute: snapshot deltaCommands , (self waypointCommandsSince: waypoints)
		labeled: anUndoLabel.
	diagramController updateCanvas
]
