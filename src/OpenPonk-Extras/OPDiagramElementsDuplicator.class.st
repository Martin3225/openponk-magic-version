"
I duplicate diagram elements (with their domain models) in an open diagram.

- Every selected node is recreated by a fresh controller of the same class through the regular creation path (#addAsTargetFor:onPosition:), so the copy is registered, rendered and undoable exactly like an element created from the palette. Its model properties are then copied by OPModelPropertiesCopier and its shape gets the original's size and local style, moved by #offset.
- Elements shown inside a duplicated node or attached to a duplicated edge (e.g. UML attributes inside a class, BORM data flows on a communication) are duplicated into the copy. A selected element whose owner is also selected is not duplicated twice.
- Edges are duplicated when both their ends were duplicated (whether the edge itself was selected or not), so e.g. an ERD entity copied with its attributes stays connected to them.
- Everything happens in a single undo transaction and the copies become the new selection, so repeating the command keeps duplicating.
"
Class {
	#name : 'OPDiagramElementsDuplicator',
	#superclass : 'Object',
	#instVars : [
		'diagramController',
		'offset',
		'duplicates',
		'topLevelDuplicates',
		'propertiesCopier'
	],
	#category : 'OpenPonk-Extras-Duplicate',
	#package : 'OpenPonk-Extras',
	#tag : 'Duplicate'
}

{ #category : 'instance creation' }
OPDiagramElementsDuplicator class >> on: aDiagramController [

	^ self new
		  diagramController: aDiagramController;
		  yourself
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> controllerForDiagramElement: aDiagramElement [

	aDiagramElement == diagramController diagramElement ifTrue: [
		^ diagramController ].
	^ diagramController
		  controllerForModel: aDiagramElement modelElement
		  ifNone: [ nil ]
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> copyBendPointsFrom: aSourceEdge to: aTargetEdge [
	"Waypoints stay nil until the user bends an edge; then they include both end points."

	| waypoints |
	waypoints := aSourceEdge instVarNamed: #waypoints.
	(waypoints isNil or: [ waypoints size <= 2 ]) ifTrue: [ ^ self ].
	aTargetEdge innerWaypoints:
		((waypoints copyFrom: 2 to: waypoints size - 1) collect: [ :each |
			 each + offset ])
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> copyDiagramElementFrom: aSourceElement to: aTargetElement position: aPointOrNil [

	(aPointOrNil isNotNil and: [ aSourceElement bounds isNotNil ]) ifTrue: [
		aTargetElement bounds: (OPNodeBounds
				 withPosition: aPointOrNil
				 extent: aSourceElement bounds extent) ].
	aSourceElement localStyle ifNotNil: [ :style |
		aTargetElement localStyle: (self copyOfStyle: style) ].
	aTargetElement isRendered ifTrue: [ aTargetElement updateRenderFromSelf ]
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> copyOfStyle: aShapeStyle [
	"A style knows the elements it styles, so it cannot be shared or shallow-copied; copy its properties into a fresh one (OPShapeStyle has no accessor for them)."

	| copy |
	copy := aShapeStyle class new.
	(aShapeStyle instVarNamed: #properties) keysAndValuesDo: [ :key :value |
		copy at: key put: value ].
	^ copy
]

{ #category : 'accessing' }
OPDiagramElementsDuplicator >> diagramController: aDiagramController [

	diagramController := aDiagramController
]

{ #category : 'duplicating' }
OPDiagramElementsDuplicator >> duplicateControllers: aCollection [
	"Duplicate the elements of the given controllers and answer controllers of the top-level copies (nodes and edges)."

	| controllers nodes |
	controllers := (aCollection reject: [ :each |
		                each isNil or: [
			                each == diagramController or: [
				                each diagramElement isNil ] ] ]) asOrderedCollection
		               removeDuplicates;
		               yourself.
	nodes := controllers reject: [ :each | each diagramElement isEdge ].
	nodes := nodes reject: [ :each | self hasAncestorAmong: nodes node: each ].
	controllers ifEmpty: [ ^ #(  ) ].
	self inUndoTransactionDo: [
		nodes do: [ :each |
			topLevelDuplicates add: (self
					 duplicateNode: each
					 into: (self parentControllerOf: each)
					 position: (self positionOfDuplicateOf: each)) ].
		self duplicateEdgesSelected: (controllers select: [ :each |
				 each diagramElement isEdge ]) ].
	self selectDuplicates.
	^ topLevelDuplicates asArray
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> duplicateEdge: anEdgeController [

	| source target duplicate |
	source := duplicates at: anEdgeController diagramElement source modelElement.
	target := duplicates at: anEdgeController diagramElement target modelElement.
	duplicate := anEdgeController class new.
	source addAsSourceFor: duplicate.
	target addAsTargetFor: duplicate.
	propertiesCopier copyFromController: anEdgeController toController: duplicate.
	self copyBendPointsFrom: anEdgeController diagramElement to: duplicate diagramElement.
	self copyDiagramElementFrom: anEdgeController diagramElement to: duplicate diagramElement position: nil.
	duplicates at: anEdgeController model put: duplicate.
	self duplicateInnerNodesOf: anEdgeController into: duplicate.
	self refresh: duplicate.
	^ duplicate
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> duplicateEdgesSelected: selectedEdges [
	"Duplicate edges whose both ends were duplicated. Edges that connect edges are handled in later rounds."

	| candidates pending |
	candidates := (diagramController controllers select: [ :each |
		               each diagramElement isNotNil and: [ each diagramElement isEdge ] ]) asOrderedCollection.
	selectedEdges do: [ :each | (candidates includes: each) ifFalse: [ candidates add: each ] ].
	pending := candidates reject: [ :each | duplicates includesKey: each model ].
	[
	| ready |
	ready := pending select: [ :each | self hasDuplicatedEnds: each ].
	ready do: [ :each |
		(self duplicateEdge: each) ifNotNil: [ :duplicate |
			(selectedEdges includes: each) ifTrue: [ topLevelDuplicates add: duplicate ] ] ].
	pending removeAll: ready.
	ready notEmpty ] whileTrue
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> duplicateInnerNodesOf: aController into: aDuplicateController [
	"Nodes shown inside a node (attributes in a class, states in a BORM participant) or attached to an edge (BORM data flows on a communication)."

	(self innerNodeControllersOf: aController) do: [ :each |
		self
			duplicateNode: each
			into: aDuplicateController
			position: (self positionOfDuplicateOf: each) ]
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> duplicateNode: aController into: aParentController position: aPointOrNil [

	| duplicate |
	duplicate := aController class new.
	aParentController addAsTargetFor: duplicate onPosition: aPointOrNil.
	propertiesCopier copyFromController: aController toController: duplicate.
	self
		copyDiagramElementFrom: aController diagramElement
		to: duplicate diagramElement
		position: aPointOrNil.
	duplicates at: aController model put: duplicate.
	self duplicateInnerNodesOf: aController into: duplicate.
	self refresh: duplicate.
	^ duplicate
]

{ #category : 'duplicating' }
OPDiagramElementsDuplicator >> duplicateRoassalShapes: aCollectionOfShapes [

	^ self duplicateControllers: (aCollectionOfShapes collect: [ :each |
			   diagramController controllerForRoassalShape: each ifNone: [ nil ] ])
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> hasAncestorAmong: aCollectionOfControllers node: aController [

	| owner |
	owner := aController diagramElement owningElement.
	[ owner isNotNil ] whileTrue: [
		(aCollectionOfControllers anySatisfy: [ :each |
			 each diagramElement == owner ]) ifTrue: [ ^ true ].
		owner := owner owningElement ].
	^ false
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> hasDuplicatedEnds: anEdgeController [

	| edge |
	edge := anEdgeController diagramElement.
	(edge source isNil or: [ edge target isNil ]) ifTrue: [ ^ false ].
	^ (duplicates includesKey: edge source modelElement) and: [
		  duplicates includesKey: edge target modelElement ]
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> inUndoTransactionDo: aBlock [

	diagramController undoManager
		ifNil: [ aBlock value ]
		ifNotNil: [ :undoManager |
		undoManager inTransactionLabeled: 'Duplicate' do: aBlock ]
]

{ #category : 'initialization' }
OPDiagramElementsDuplicator >> initialize [

	super initialize.
	offset := 20 @ 20.
	duplicates := IdentityDictionary new.
	topLevelDuplicates := OrderedCollection new.
	propertiesCopier := OPModelPropertiesCopier new
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> collectInnerNodeControllersOf: aDiagramElement into: aCollection [
	"Depth-first in display order. Stop at elements that are the diagram element of their own controller (their content is duplicated with them); descend through the rest (labels, compartments sharing the owner's model...)."

	aDiagramElement ownedElements do: [ :each |
		each isEdge ifFalse: [
			| controller |
			controller := self controllerForDiagramElement: each.
			(controller isNotNil and: [ controller diagramElement == each ])
				ifTrue: [ aCollection add: controller ]
				ifFalse: [ self collectInnerNodeControllersOf: each into: aCollection ] ] ]
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> innerNodeControllersOf: aController [
	"Controllers of nodes shown inside aController's shape (e.g. attributes of a class), in the order of the owner's model (diagram elements may be stored in a different order)."

	| controllers modelOrder |
	controllers := OrderedCollection new.
	self
		collectInnerNodeControllersOf: aController diagramElement
		into: controllers.
	controllers := controllers select: [ :each |
		               each ~~ aController and: [
			               propertiesCopier shouldDuplicateInnerModel: each model ] ].
	modelOrder := aController viewModel
		              ifNil: [ #(  ) ]
		              ifNotNil: [ :viewModel | viewModel childrenModels asArray ].
	^ controllers asArray sort: [ :a :b |
		  (modelOrder indexOf: a model ifAbsent: [ SmallInteger maxVal ])
		  <= (modelOrder indexOf: b model ifAbsent: [ SmallInteger maxVal ]) ]
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> refresh: aController [

	aController viewModel ifNotNil: [ :viewModel | viewModel modelChanged ].
	aController diagramElement ifNotNil: [ :element |
		element isRendered ifTrue: [ aController modelChanged ] ]
]

{ #category : 'accessing' }
OPDiagramElementsDuplicator >> offset [

	^ offset
]

{ #category : 'accessing' }
OPDiagramElementsDuplicator >> offset: aPoint [

	offset := aPoint
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> parentControllerOf: aController [

	| owner |
	owner := aController diagramElement owningElementWithPossibleController.
	^ (owner isNil or: [ owner == diagramController diagramElement ])
		  ifTrue: [ diagramController ]
		  ifFalse: [
			  (duplicates at: owner modelElement ifAbsent: [ nil ]) ifNil: [
				  self controllerForDiagramElement: owner ] ]
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> positionOfDuplicateOf: aController [
	"Nodes laid out by their owner (e.g. attributes in a class) get no position."

	| element |
	element := aController diagramElement.
	(element isPositionableByUser and: [ element bounds isNotNil ])
		ifFalse: [ ^ nil ].
	^ element bounds position + offset
]

{ #category : 'private' }
OPDiagramElementsDuplicator >> selectDuplicates [

	| shapes |
	shapes := (topLevelDuplicates
		           collect: [ :each | each roassalShape ]
		           thenSelect: [ :each | each isNotNil ]) asArray.
	shapes ifEmpty: [ ^ self ].
	diagramController canvas
		propertyAt: OPRSSelectableCanvas
		ifPresent: [ :selection |
			selection
				selectShapes: (RSGroup withAll: shapes)
				byEvent: (RSMouseClick new
						 canvas: diagramController canvas;
						 position: shapes first position;
						 yourself) ]
]
