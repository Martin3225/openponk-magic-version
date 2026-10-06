"
Badges on the canvas that point at elements with problems: a red circle for errors, an amber one for warnings, with the number of problems. They sit on the top-right corner of a class (and follow it when it is dragged) or in the middle of a relation. Hovering shows the problems, clicking selects the problem in the problems panel.

The badges are plain Roassal shapes outside the model: they are not selectable, not saved, not undoable, and they are removed while the diagram is exported (see #hideOn:during:), so they never get into a submitted picture.
"
Class {
	#name : 'OPOntoUMLProblemMarkers',
	#superclass : 'Object',
	#instVars : [
		'diagramController',
		'shapes',
		'problems',
		'hidden',
		'onClick'
	],
	#category : 'OpenPonk-Extras-OntoUML-Problems',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Problems'
}

{ #category : 'exporting' }
OPOntoUMLProblemMarkers class >> hideOn: aDiagramController during: aBlock [

	| markers |
	markers := (aDiagramController isNil or: [ aDiagramController canvas isNil ]) ifFalse: [
		           aDiagramController canvas propertyAt: self ifAbsent: [ nil ] ].
	^ markers
		  ifNil: [ aBlock value ]
		  ifNotNil: [ markers hideDuring: aBlock ]
]

{ #category : 'instance creation' }
OPOntoUMLProblemMarkers class >> on: aDiagramController [
	"The markers of the diagram's canvas."

	^ aDiagramController canvas
		  propertyAt: self
		  ifAbsentPut: [ self new setDiagramController: aDiagramController ]
]

{ #category : 'private' }
OPOntoUMLProblemMarkers >> addMarkerFor: aCollectionOfProblems on: aTargetShape [

	| marker |
	marker := self markerFor: aCollectionOfProblems.
	diagramController canvas add: marker.
	shapes add: marker.
	(aTargetShape respondsTo: #controlPoints)
		ifTrue: [ marker translateTo: (self middleOf: aTargetShape) ]
		ifFalse: [
			RSLocation new
				inner;
				top;
				right;
				offset: 6 @ -6;
				stick: marker on: aTargetShape ]
]

{ #category : 'colors' }
OPOntoUMLProblemMarkers >> errorColor [

	^ Color fromHexString: 'D93025'
]

{ #category : 'showing' }
OPOntoUMLProblemMarkers >> hideDuring: aBlock [

	hidden := hidden + 1.
	self removeShapes.
	^ aBlock ensure: [
		  hidden := hidden - 1.
		  self show: problems ]
]

{ #category : 'initialization' }
OPOntoUMLProblemMarkers >> initialize [

	super initialize.
	shapes := OrderedCollection new.
	problems := #(  ).
	hidden := 0
]

{ #category : 'private' }
OPOntoUMLProblemMarkers >> markerFor: aCollectionOfProblems [

	| isError circle label marker |
	isError := aCollectionOfProblems anySatisfy: [ :each | each isError ].
	circle := RSCircle new
		          radius: 8;
		          color: (isError
				           ifTrue: [ self errorColor ]
				           ifFalse: [ self warningColor ]);
		          border: (RSBorder new
				           color: Color white;
				           width: 1.5;
				           yourself);
		          yourself.
	label := RSLabel new
		         text: (aCollectionOfProblems size > 1
				          ifTrue: [ aCollectionOfProblems size printString ]
				          ifFalse: [ '!' ]);
		         color: Color white;
		         fontSize: 10;
		         bold;
		         yourself.
	marker := RSComposite new
		          shapes: {
				          circle.
				          label };
		          model: aCollectionOfProblems;
		          yourself.
	marker adjustToChildren.
	marker @ (RSPopup text: [ :elementProblems |
		  String cr join: (elementProblems collect: [ :each | each title ]) ]).
	marker
		when: RSMouseLeftClick
		do: [ :event | onClick ifNotNil: [ onClick value: aCollectionOfProblems first ] ]
		for: self.
	^ marker
]

{ #category : 'private' }
OPOntoUMLProblemMarkers >> middleOf: aLineShape [

	| points |
	points := aLineShape controlPoints.
	points ifEmpty: [ ^ aLineShape position ].
	^ points size odd
		  ifTrue: [ points at: points size + 1 // 2 ]
		  ifFalse: [ ((points at: points size // 2) + (points at: points size // 2 + 1)) / 2 ]
]

{ #category : 'accessing' }
OPOntoUMLProblemMarkers >> onClick: aOneArgBlock [
	"Called with the (first) problem of a clicked marker."

	onClick := aOneArgBlock
]

{ #category : 'private' }
OPOntoUMLProblemMarkers >> removeShapes [

	shapes do: [ :each | each remove ].
	shapes removeAll
]

{ #category : 'initialization' }
OPOntoUMLProblemMarkers >> setDiagramController: aDiagramController [

	diagramController := aDiagramController
]

{ #category : 'private' }
OPOntoUMLProblemMarkers >> shapeOf: anElement [

	| controller |
	controller := diagramController controllerForModel: anElement ifNone: [ ^ nil ].
	(controller diagramElement isNil or: [ controller diagramElement isRendered not ]) ifTrue: [ ^ nil ].
	^ controller roassalShape
]

{ #category : 'accessing' }
OPOntoUMLProblemMarkers >> shapes [

	^ shapes
]

{ #category : 'showing' }
OPOntoUMLProblemMarkers >> show: aCollectionOfProblems [

	| byElement |
	self removeShapes.
	problems := aCollectionOfProblems.
	hidden > 0 ifTrue: [ ^ self ].
	byElement := IdentityDictionary new.
	problems do: [ :each |
		(byElement at: each element ifAbsentPut: [ OrderedCollection new ]) add: each ].
	byElement keysAndValuesDo: [ :element :elementProblems |
		(self shapeOf: element) ifNotNil: [ :target |
			[ self addMarkerFor: elementProblems on: target ]
				on: Error
				do: [ "an element in the middle of rendering; next check places it" ] ] ].
	diagramController canvas signalUpdate
]

{ #category : 'colors' }
OPOntoUMLProblemMarkers >> warningColor [

	^ Color fromHexString: 'E8A100'
]
