"
Badges that point at elements with problems: a red circle for errors, an amber one for warnings, with the number of problems. They sit on the top-right corner of a class or in the middle of a relation. Hovering shows the problems, clicking selects the problem in the problems panel.

The badges are drawn by a transparent morph laid over the canvas (OPOntoUMLProblemBadgesMorph), not as Roassal shapes: they are no part of the diagram (not among the canvas shapes, not saved, not exported), they keep their size at any zoom, and their places are computed whenever they are drawn, so they follow dragged elements, panning and zooming.
"
Class {
	#name : 'OPOntoUMLProblemMarkers',
	#superclass : 'Object',
	#instVars : [
		'diagramController',
		'problemsByElement',
		'onClick',
		'overlay'
	],
	#category : 'OpenPonk-Extras-OntoUML-Problems',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Problems'
}

{ #category : 'instance creation' }
OPOntoUMLProblemMarkers class >> on: aDiagramController [
	"The markers of the diagram's canvas."

	^ aDiagramController canvas
		  propertyAt: self
		  ifAbsentPut: [ self new setDiagramController: aDiagramController ]
]

{ #category : 'badges' }
OPOntoUMLProblemMarkers >> badgeAt: aPoint [
	"The badge under aPoint (world coordinates), or nil."

	^ self badges
		  detect: [ :each | (each center distanceTo: aPoint) <= (self radius + 1) ]
		  ifNone: [ nil ]
]

{ #category : 'badges' }
OPOntoUMLProblemMarkers >> badgeCenterOn: aShape [

	| canvas morph |
	canvas := diagramController canvas.
	morph := canvas morph.
	(aShape respondsTo: #controlPoints) ifTrue: [
		^ morph position + (canvas camera fromSpaceToPixel: (self middleOf: aShape)) ].
	^ morph position + (canvas camera fromSpaceToPixel: aShape encompassingRectangle topRight)
	  + (-3 @ 3)
]

{ #category : 'badges' }
OPOntoUMLProblemMarkers >> badges [
	"Badges of the elements shown in the diagram, placed where their shapes are now."

	| badges |
	badges := OrderedCollection new.
	diagramController canvas morph ifNil: [ ^ badges ].
	problemsByElement keysAndValuesDo: [ :element :problems |
		(self shapeOf: element) ifNotNil: [ :shape |
			[
			badges add: (OPOntoUMLProblemBadge new
					 center: (self badgeCenterOn: shape);
					 problems: problems;
					 yourself) ]
				on: Error
				do: [ "an element in the middle of rendering" ] ] ].
	^ badges
]

{ #category : 'events' }
OPOntoUMLProblemMarkers >> clicked: aBadge [

	onClick ifNotNil: [ onClick value: aBadge problems first ]
]

{ #category : 'initialization' }
OPOntoUMLProblemMarkers >> ensureOverlay [

	| morph |
	morph := diagramController canvas morph ifNil: [ ^ self ].
	(overlay notNil and: [ overlay owner == morph ]) ifTrue: [ ^ self ].
	overlay ifNotNil: [ overlay delete ].
	overlay := OPOntoUMLProblemBadgesMorph new
		           markers: self;
		           bounds: morph bounds;
		           yourself.
	morph addMorphFront: overlay
]

{ #category : 'initialization' }
OPOntoUMLProblemMarkers >> initialize [

	super initialize.
	problemsByElement := OrderedIdentityDictionary new
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
	"Called with the (first) problem of a clicked badge."

	onClick := aOneArgBlock
]

{ #category : 'accessing' }
OPOntoUMLProblemMarkers >> overlay [

	^ overlay
]

{ #category : 'badges' }
OPOntoUMLProblemMarkers >> radius [

	^ 8
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

{ #category : 'showing' }
OPOntoUMLProblemMarkers >> show: aCollectionOfProblems [

	problemsByElement := OrderedIdentityDictionary new.
	aCollectionOfProblems do: [ :each |
		(problemsByElement at: each element ifAbsentPut: [ OrderedCollection new ]) add: each ].
	self ensureOverlay.
	overlay ifNotNil: [ overlay changed ]
]
