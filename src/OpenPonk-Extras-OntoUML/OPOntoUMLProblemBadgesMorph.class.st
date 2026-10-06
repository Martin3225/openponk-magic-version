"
Transparent morph over the canvas of a diagram that draws the badges of OPOntoUMLProblemMarkers. It covers the whole canvas but takes the mouse only over a badge (see #containsPoint:), so everything else goes to the canvas below. Hovering a badge shows its problems, clicking it selects the problem in the problems panel.
"
Class {
	#name : 'OPOntoUMLProblemBadgesMorph',
	#superclass : 'Morph',
	#instVars : [
		'markers'
	],
	#category : 'OpenPonk-Extras-OntoUML-Problems',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Problems'
}

{ #category : 'geometry' }
OPOntoUMLProblemBadgesMorph >> containsPoint: aPoint [

	^ markers notNil and: [ (markers badgeAt: aPoint) notNil ]
]

{ #category : 'drawing' }
OPOntoUMLProblemBadgesMorph >> drawBadge: aBadge on: aCanvas [

	| radius font text |
	radius := markers radius.
	aCanvas
		fillOval: (Rectangle center: aBadge center extent: (2 * radius) @ (2 * radius))
		color: aBadge color
		borderWidth: 1
		borderColor: Color white.
	font := StandardFonts defaultFont emphasized: TextEmphasis bold emphasisCode.
	text := aBadge label.
	aCanvas
		drawString: text
		at: aBadge center - (((font widthOfString: text) @ font height) / 2) rounded
		font: font
		color: Color white
]

{ #category : 'drawing' }
OPOntoUMLProblemBadgesMorph >> drawOn: aCanvas [

	(owner notNil and: [ bounds ~= owner bounds ]) ifTrue: [ self bounds: owner bounds ].
	markers ifNil: [ ^ self ].
	markers badges do: [ :each | self drawBadge: each on: aCanvas ]
]

{ #category : 'event handling' }
OPOntoUMLProblemBadgesMorph >> handlesMouseDown: anEvent [

	^ true
]

{ #category : 'event handling' }
OPOntoUMLProblemBadgesMorph >> handlesMouseOver: anEvent [

	^ true
]

{ #category : 'initialization' }
OPOntoUMLProblemBadgesMorph >> initialize [

	super initialize.
	self color: Color transparent
]

{ #category : 'accessing' }
OPOntoUMLProblemBadgesMorph >> markers: anOPOntoUMLProblemMarkers [

	markers := anOPOntoUMLProblemMarkers
]

{ #category : 'event handling' }
OPOntoUMLProblemBadgesMorph >> mouseDown: anEvent [

	(markers badgeAt: anEvent position) ifNotNil: [ :badge |
		self deleteBalloon.
		markers clicked: badge ]
]

{ #category : 'event handling' }
OPOntoUMLProblemBadgesMorph >> mouseEnter: anEvent [

	(markers badgeAt: anEvent position) ifNotNil: [ :badge |
		self showBalloon: badge tooltip hand: anEvent hand ]
]

{ #category : 'event handling' }
OPOntoUMLProblemBadgesMorph >> mouseLeave: anEvent [

	self deleteBalloon
]
