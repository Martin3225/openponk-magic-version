"
I arrange a diagram anew, ignoring where its nodes are, so that its edges cross as little as possible, and then tidy it up (OPDiagramTidier: bends around obstacles, labels on free places). Everything is one undoable step.

1. Start: rows by generalizations (a general class above its specific ones), the other nodes in the average row of their neighbors, each row sorted by the barycenters of the neighbors.
2. Stress majorization: nodes are moved so that their distances match the lengths of the shortest paths between them in the graph, which untangles sparse graphs (class diagrams are mostly trees joined by a few associations). After each round, specific classes are pushed below their general ones.
3. The positions are snapped to a grid of equal cells, big enough for the largest node with room for edge labels in between (the most connected nodes pick their cell first).
4. Simulated annealing improves the grid: a random node moves to a nearby cell (swapping places if the cell is taken), and the change is kept when it lowers the cost, or with a probability that falls as the search cools down. The cost counts crossings of straight edges (#crossingCost), edges passing through other nodes (#nodeHitCost), specific classes not below their general ones (#generalizationCost), edge length and a slight pull to the middle that keeps unconnected nodes together. Empty rows and columns are removed and the compact grid is annealed again (the slopes of the edges changed), then every node takes the best nearby cell while that helps. This runs with several fixed random seeds and the cheapest result wins, so the same diagram is always arranged the same way.
5. The grid is placed where the diagram started.

Nodes are numbered (their order sorted by position) and kept in arrays, as the search evaluates the cost hundreds of thousands of times. Containers (nodes with nodes inside) stay where they are.
"
Class {
	#name : 'OPDiagramRearranger',
	#superclass : 'Object',
	#instVars : [
		'diagramController',
		'tidier',
		'shapes',
		'extents',
		'edges',
		'incident',
		'cells',
		'occupied',
		'centers',
		'rectangles',
		'columns',
		'rows',
		'cellExtent'
	],
	#category : 'OpenPonk-Extras-Layout',
	#package : 'OpenPonk-Extras',
	#tag : 'Layout'
}

{ #category : 'instance creation' }
OPDiagramRearranger class >> on: aDiagramController [

	^ self new
		  diagramController: aDiagramController;
		  yourself
]

{ #category : 'private - annealing' }
OPDiagramRearranger >> anneal: iterationsPerNode from: aTemperature seed: aNumber [
	"Cool down from aTemperature to 2; keep the cheapest arrangement seen."

	| random iterations best bestCost cost |
	random := Random seed: aNumber.
	iterations := iterationsPerNode * shapes size max: 10 * iterationsPerNode.
	cost := self totalCost.
	bestCost := cost.
	best := cells copy.
	1 to: iterations do: [ :i |
		| progress node from target other moved before delta temperature |
		progress := i asFloat / iterations.
		temperature := aTemperature * (2.0 / aTemperature raisedTo: progress).
		node := random nextInteger: shapes size.
		from := cells at: node.
		target := self randomCellNear: from progress: progress random: random.
		target = from ifFalse: [
			other := occupied at: target ifAbsent: [ nil ].
			moved := other ifNil: [ { node } ] ifNotNil: [ { node. other } ].
			before := self localCostOf: moved.
			self swap: node to: target.
			delta := (self localCostOf: moved) - before.
			(delta <= 0 or: [ random next < (delta negated / temperature) exp ])
				ifTrue: [
					cost := cost + delta.
					cost < bestCost ifTrue: [
						bestCost := cost.
						best := cells copy ] ]
				ifFalse: [ self swap: node to: from ] ] ].
	self useCells: best
]

{ #category : 'private' }
OPDiagramRearranger >> apply [
	"Move the shapes into their cells, the grid starting where the nodes started."

	| origin minimum |
	minimum := cells inject: cells first into: [ :min :each | min min: each ].
	origin := (shapes inject: shapes first encompassingRectangle into: [ :rectangle :each |
		           rectangle merge: each encompassingRectangle ]) origin.
	shapes doWithIndex: [ :each :i |
		| center |
		center := origin + ((cells at: i) - minimum * cellExtent) + (cellExtent / 2).
		each translateBy: (center - each encompassingRectangle center) rounded ]
]

{ #category : 'private - start' }
OPDiagramRearranger >> barycenterOf: aNode [

	| neighbors |
	neighbors := self neighborsOf: aNode.
	neighbors ifEmpty: [ ^ (cells at: aNode) x ].
	^ (neighbors inject: 0 into: [ :sum :each | sum + (cells at: each) x ]) / neighbors size
]

{ #category : 'private - annealing' }
OPDiagramRearranger >> compact [
	"Remove empty rows and columns, keeping one free row and column around."

	| usedColumns usedRows old |
	usedColumns := (cells collect: [ :each | each x ]) asSet asSortedCollection asArray.
	usedRows := (cells collect: [ :each | each y ]) asSet asSortedCollection asArray.
	old := cells copy.
	occupied := Dictionary new.
	old doWithIndex: [ :cell :node |
		self put: node at: (usedColumns indexOf: cell x) @ (usedRows indexOf: cell y) ].
	columns := usedColumns size + 2.
	rows := usedRows size + 2
]

{ #category : 'private - cost' }
OPDiagramRearranger >> costOfEdge: anEdge [
	"Length, and a general class not above its specific one."

	| cost |
	cost := (centers at: (anEdge at: 1)) distanceTo: (centers at: (anEdge at: 2)).
	((anEdge at: 3) and: [ (cells at: (anEdge at: 1)) y <= (cells at: (anEdge at: 2)) y ]) ifTrue: [
		cost := cost + self generalizationCost ].
	^ cost
]

{ #category : 'private - cost' }
OPDiagramRearranger >> crossingCost [

	^ 1000
]

{ #category : 'private - cost' }
OPDiagramRearranger >> crossingsOf: anEdge with: anotherEdge [
	"Whether the straight edges between the centers of their nodes cross (1) or not (0); edges sharing a node meet there."

	| a b c d |
	a := anEdge at: 1.
	b := anEdge at: 2.
	c := anotherEdge at: 1.
	d := anotherEdge at: 2.
	(a = c or: [ a = d or: [ b = c or: [ b = d ] ] ]) ifTrue: [ ^ 0 ].
	^ (tidier
		   intersectionOf: (centers at: a)
		   to: (centers at: b)
		   with: (centers at: c)
		   to: (centers at: d))
		  ifNil: [ 0 ]
		  ifNotNil: [ 1 ]
]

{ #category : 'accessing' }
OPDiagramRearranger >> diagramController: aDiagramController [

	diagramController := aDiagramController
]

{ #category : 'private - start' }
OPDiagramRearranger >> enforceGeneralizationsIn: positions [
	"Push specific classes at least a row below their general ones."

	3 timesRepeat: [
		edges do: [ :each |
			(each at: 3) ifTrue: [
				| specific general shortage |
				specific := positions at: (each at: 1).
				general := positions at: (each at: 2).
				shortage := cellExtent y - (specific y - general y).
				shortage > 0 ifTrue: [
					positions at: (each at: 1) put: specific + (0 @ (shortage / 2)).
					positions at: (each at: 2) put: general - (0 @ (shortage / 2)) ] ] ] ]
]

{ #category : 'private - cost' }
OPDiagramRearranger >> generalizationCost [

	^ 5000
]

{ #category : 'private - cost' }
OPDiagramRearranger >> gravityCost [
	"Per pixel from the middle of the grid."

	^ 0.1
]

{ #category : 'private - cost' }
OPDiagramRearranger >> hitsOf: anEdge [
	"Nodes the straight edge passes through, other than its ends."

	| a b from to count |
	a := anEdge at: 1.
	b := anEdge at: 2.
	from := centers at: a.
	to := centers at: b.
	count := 0.
	1 to: shapes size do: [ :each |
		(each ~= a and: [ each ~= b and: [ self segmentFrom: from to: to hits: (rectangles at: each) ] ])
			ifTrue: [ count := count + 1 ] ].
	^ count
]

{ #category : 'private - start' }
OPDiagramRearranger >> hopDistances [
	"For each node, the number of edges on the shortest path to every node (nil when not connected), by breadth-first search."

	^ (1 to: shapes size) collect: [ :start |
		  | reached queue |
		  reached := Array new: shapes size.
		  reached at: start put: 0.
		  queue := OrderedCollection with: start.
		  [ queue isEmpty ] whileFalse: [
			  | node |
			  node := queue removeFirst.
			  (self neighborsOf: node) do: [ :each |
				  (reached at: each) ifNil: [
					  reached at: each put: (reached at: node) + 1.
					  queue add: each ] ] ].
		  reached ]
]

{ #category : 'private - annealing' }
OPDiagramRearranger >> improveGreedily [
	"Finish the annealing: move each node to the cell (within two of its own, swapping when taken) that lowers the cost most, until no move helps."

	| passes improved |
	passes := 0.
	[
	improved := false.
	1 to: shapes size do: [ :node |
		| from bestCell bestDelta |
		from := cells at: node.
		bestDelta := -0.5.
		bestCell := nil.
		(from x - 2 max: 0) to: (from x + 2 min: columns - 1) do: [ :x |
			(from y - 2 max: 0) to: (from y + 2 min: rows - 1) do: [ :y |
				| target other moved before delta |
				target := x @ y.
				target = from ifFalse: [
					other := occupied at: target ifAbsent: [ nil ].
					moved := other ifNil: [ { node } ] ifNotNil: [ { node. other } ].
					before := self localCostOf: moved.
					self swap: node to: target.
					delta := (self localCostOf: moved) - before.
					self swap: node to: from.
					delta < bestDelta ifTrue: [
						bestDelta := delta.
						bestCell := target ] ] ] ].
		bestCell ifNotNil: [
			self swap: node to: bestCell.
			improved := true ] ].
	improved and: [ (passes := passes + 1) < 10 ] ] whileTrue
]

{ #category : 'private - start' }
OPDiagramRearranger >> initialPlacement [
	"Rows by generalizations (general classes above), columns by the barycenter method."

	| rank byRow |
	rank := Array new: shapes size withAll: 0.
	shapes size timesRepeat: [
		edges do: [ :each |
			(each at: 3) ifTrue: [
				rank at: (each at: 1) put: ((rank at: (each at: 1)) max: (rank at: (each at: 2)) + 1) ] ] ].
	3 timesRepeat: [
		1 to: shapes size do: [ :node |
			((incident at: node) noneSatisfy: [ :each | each at: 3 ]) ifTrue: [
				(self neighborsOf: node) ifNotEmpty: [ :neighbors |
					rank at: node put: ((neighbors inject: 0 into: [ :sum :each | sum + (rank at: each) ])
						 / neighbors size) rounded ] ] ] ].
	byRow := Dictionary new.
	1 to: shapes size do: [ :each | (byRow at: (rank at: each) ifAbsentPut: [ OrderedCollection new ]) add: each ].
	columns := byRow values inject: 1 into: [ :max :each | max max: each size ].
	rows := (rank inject: 0 into: [ :max :each | max max: each ]) + 1.
	self placeRows: byRow.
	4 timesRepeat: [
		byRow do: [ :row | row sort: [ :a :b | (self barycenterOf: a) <= (self barycenterOf: b) ] ].
		self placeRows: byRow ]
]

{ #category : 'private - cost' }
OPDiagramRearranger >> localCostOf: movedNodes [
	"The part of the cost that changes when movedNodes move: their edges (length, crossings with all edges, nodes they pass through), other edges passing through them, and their pull to the middle."

	| affected cost middle |
	affected := OrderedCollection new.
	movedNodes do: [ :node |
		(incident at: node) do: [ :each | (affected identityIncludes: each) ifFalse: [ affected add: each ] ] ].
	cost := 0.
	affected doWithIndex: [ :edge :i |
		cost := cost + (self costOfEdge: edge) + ((self hitsOf: edge) * self nodeHitCost).
		edges do: [ :other |
			| j |
			j := affected identityIndexOf: other.
			(j = 0 or: [ j > i ]) ifTrue: [
				cost := cost + ((self crossingsOf: edge with: other) * self crossingCost) ] ] ].
	movedNodes do: [ :node |
		| rectangle |
		rectangle := rectangles at: node.
		edges do: [ :each |
			((affected identityIncludes: each) not and: [
				 self segmentFrom: (centers at: (each at: 1)) to: (centers at: (each at: 2)) hits: rectangle ])
				ifTrue: [ cost := cost + self nodeHitCost ] ] ].
	middle := (columns @ rows) * cellExtent / 2.
	movedNodes do: [ :node | cost := cost + (((centers at: node) distanceTo: middle) * self gravityCost) ].
	^ cost
]

{ #category : 'private' }
OPDiagramRearranger >> neighborsOf: aNode [

	^ (incident at: aNode) collect: [ :each |
		  (each at: 1) = aNode
			  ifTrue: [ each at: 2 ]
			  ifFalse: [ each at: 1 ] ]
]

{ #category : 'private - cost' }
OPDiagramRearranger >> nodeHitCost [

	^ 2000
]

{ #category : 'private' }
OPDiagramRearranger >> place: movableShapes [
	"Arrange the shapes (the shapes only, OPDiagramTidier records the changes)."

	| indexes start bestCells bestCost |
	"Sorted by position: the controllers come in no fixed order, and the result should not depend on it."
	shapes := movableShapes asArray sorted: [ :a :b |
		          | first second |
		          first := a encompassingRectangle origin.
		          second := b encompassingRectangle origin.
		          first x < second x or: [ first x = second x and: [ first y <= second y ] ] ].
	shapes size < 2 ifTrue: [ ^ self ].
	indexes := IdentityDictionary new.
	shapes doWithIndex: [ :each :i | indexes at: each put: i ].
	extents := shapes collect: [ :each | each encompassingRectangle extent ].
	edges := OrderedCollection new.
	tidier edgeControllers do: [ :each |
		| line from to |
		line := each roassalShape.
		from := indexes at: line from ifAbsent: [ nil ].
		to := indexes at: line to ifAbsent: [ nil ].
		(from notNil and: [ to notNil and: [ from ~= to ] ]) ifTrue: [
			edges add: {
					from.
					to.
					(tidier isGeneralization: each) } ] ].
	edges := edges asArray sort: [ :a :b |
		         (a at: 1) < (b at: 1) or: [ (a at: 1) = (b at: 1) and: [ (a at: 2) <= (b at: 2) ] ] ].
	incident := (1 to: shapes size) collect: [ :each | OrderedCollection new ].
	edges do: [ :each |
		(incident at: (each at: 1)) add: each.
		(incident at: (each at: 2)) add: each ].
	cellExtent := (extents inject: 0 @ 0 into: [ :max :each | max max: each ]) + (100 @ 90).
	cells := Array new: shapes size.
	centers := Array new: shapes size.
	rectangles := Array new: shapes size.
	occupied := Dictionary new.
	self initialPlacement.
	self snap: self stressPositions.
	start := cells copy -> (columns @ rows).
	bestCost := nil.
	#( 42 7 99 ) do: [ :seed |
		self useCells: start key.
		columns := start value x.
		rows := start value y.
		self anneal: 200 from: 400 seed: seed.
		"Removing empty rows and columns changes the slopes of edges, so improve the compact grid again."
		self compact.
		self anneal: 80 from: 50 seed: seed.
		self compact.
		self improveGreedily.
		(bestCost isNil or: [ self totalCost < bestCost ]) ifTrue: [
			bestCost := self totalCost.
			bestCells := cells copy -> (columns @ rows) ] ].
	self useCells: bestCells key.
	columns := bestCells value x.
	rows := bestCells value y.
	self apply
]

{ #category : 'private - start' }
OPDiagramRearranger >> placeRows: rowsByRank [
	"Put each row centered into its grid row, in its order."

	occupied removeAll.
	rowsByRank keysAndValuesDo: [ :rank :row |
		row doWithIndex: [ :each :i | self put: each at: (columns - row size) // 2 + i - 1 @ rank ] ]
]

{ #category : 'private' }
OPDiagramRearranger >> put: aNode at: aCell [

	| center |
	cells at: aNode put: aCell.
	occupied at: aCell put: aNode.
	center := aCell * cellExtent + (cellExtent / 2).
	centers at: aNode put: center.
	rectangles at: aNode put: (Rectangle center: center extent: (extents at: aNode))
]

{ #category : 'private - annealing' }
OPDiagramRearranger >> randomCellNear: aCell progress: aFraction random: aRandom [
	"A cell of the grid within a radius that shrinks from 3 to 1 as the search goes on."

	| radius |
	radius := (3 * (1 - aFraction)) rounded max: 1.
	^ (aCell x + ((aRandom nextInteger: 2 * radius + 1) - radius - 1) min: columns - 1 max: 0)
	  @ (aCell y + ((aRandom nextInteger: 2 * radius + 1) - radius - 1) min: rows - 1 max: 0)
]

{ #category : 'rearranging' }
OPDiagramRearranger >> rearrange [

	tidier := OPDiagramTidier on: diagramController.
	tidier tidyLabeled: 'Rearrange' after: [ :movableShapes :fixedShapes | self place: movableShapes ]
]

{ #category : 'private - cost' }
OPDiagramRearranger >> segmentFrom: p to: q hits: aRectangle [
	"Liang-Barsky clipping: whether the segment touches the rectangle."

	| dx dy t0 t1 |
	((p x max: q x) < aRectangle left or: [
		 (p x min: q x) > aRectangle right or: [
			 (p y max: q y) < aRectangle top or: [ (p y min: q y) > aRectangle bottom ] ] ]) ifTrue: [
		^ false ].
	dx := q x - p x.
	dy := q y - p y.
	t0 := 0.
	t1 := 1.
	{
		(dx negated -> (p x - aRectangle left)).
		(dx -> (aRectangle right - p x)).
		(dy negated -> (p y - aRectangle top)).
		(dy -> (aRectangle bottom - p y)) } do: [ :each |
		each key = 0
			ifTrue: [ each value < 0 ifTrue: [ ^ false ] ]
			ifFalse: [
				| r |
				r := each value / each key.
				each key < 0
					ifTrue: [
						r > t1 ifTrue: [ ^ false ].
						t0 := t0 max: r ]
					ifFalse: [
						r < t0 ifTrue: [ ^ false ].
						t1 := t1 min: r ] ] ].
	^ true
]

{ #category : 'private - start' }
OPDiagramRearranger >> snap: positions [
	"Give every node the free grid cell nearest to its position, the most connected nodes first."

	| minimum maximum |
	minimum := positions inject: positions first into: [ :min :each | min min: each ].
	maximum := positions inject: positions first into: [ :max :each | max max: each ].
	columns := ((maximum x - minimum x) / cellExtent x) ceiling + 3.
	rows := ((maximum y - minimum y) / cellExtent y) ceiling + 3.
	occupied removeAll.
	((1 to: shapes size) asArray sort: [ :a :b | (incident at: a) size >= (incident at: b) size ])
		do: [ :node |
			| ideal radius found |
			ideal := (positions at: node) - minimum / cellExtent + (1 @ 1).
			radius := 0.
			[
			found := nil.
			(ideal x rounded - radius to: ideal x rounded + radius) do: [ :x |
				(ideal y rounded - radius to: ideal y rounded + radius) do: [ :y |
					((x between: 0 and: columns - 1) and: [
						 (y between: 0 and: rows - 1) and: [ (occupied includesKey: x @ y) not ] ]) ifTrue: [
						(found isNil or: [ (x @ y distanceTo: ideal) < (found distanceTo: ideal) ]) ifTrue: [
							found := x @ y ] ] ] ].
			found isNil and: [ radius < (columns max: rows) ] ] whileTrue: [ radius := radius + 1 ].
			found ifNil: [
				columns := columns + 1.
				found := columns - 1 @ 0 ].
			self put: node at: found ]
]

{ #category : 'private - start' }
OPDiagramRearranger >> stressPositions [
	"Stress majorization: positions whose distances match the shortest paths in the graph (the unit is a cell), starting from the cells of #initialPlacement."

	| positions hops unit unreachable |
	positions := centers copy.
	hops := self hopDistances.
	unit := cellExtent x + cellExtent y / 2.
	unreachable := (hops inject: 1 into: [ :max :each |
		                each inject: max into: [ :m :hop | hop ifNil: [ m ] ifNotNil: [ m max: hop ] ] ]) + 1.
	100 timesRepeat: [
		1 to: shapes size do: [ :node |
			| own sum weights |
			own := positions at: node.
			sum := 0 @ 0.
			weights := 0.
			1 to: shapes size do: [ :other |
				other = node ifFalse: [
					| target weight delta distance |
					target := ((hops at: node) at: other) ifNil: [ unreachable ].
					target := target * unit.
					weight := 1.0 / (target * target).
					delta := own - (positions at: other).
					distance := delta r.
					distance < 0.01 ifTrue: [
						delta := (node - other) @ 1.
						distance := delta r ].
					sum := sum + ((positions at: other) + (delta * (target / distance)) * weight).
					weights := weights + weight ] ].
			positions at: node put: sum / weights ].
		self enforceGeneralizationsIn: positions ].
	^ positions
]

{ #category : 'private - annealing' }
OPDiagramRearranger >> swap: aNode to: aCell [
	"Move aNode to aCell; a node already there takes the cell of aNode."

	| from other |
	from := cells at: aNode.
	other := occupied at: aCell ifAbsent: [ nil ].
	occupied removeKey: from.
	self put: aNode at: aCell.
	other ifNotNil: [ self put: other at: from ]
]

{ #category : 'private - cost' }
OPDiagramRearranger >> totalCost [

	^ self localCostOf: (1 to: shapes size)
]

{ #category : 'private - annealing' }
OPDiagramRearranger >> useCells: anArray [

	occupied := Dictionary new.
	anArray doWithIndex: [ :cell :node | self put: node at: cell ]
]
