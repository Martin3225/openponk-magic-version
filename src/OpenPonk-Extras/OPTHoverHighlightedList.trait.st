"
I add a hover highlight to list morphs used as drop-down popups.

I track the row under the mouse pointer from mouse-over events (Morphic sends #mouseMove: only while a button is pressed) and answer a highlight color for that row through the #backgroundColorFor: hook that LazyListMorph uses while drawing.
"
Trait {
	#name : 'OPTHoverHighlightedList',
	#instVars : [
		'hoverRow'
	],
	#category : 'OpenPonk-Extras-Hover',
	#package : 'OpenPonk-Extras',
	#tag : 'Hover'
}

{ #category : 'drawing' }
OPTHoverHighlightedList >> backgroundColorFor: aRow [

	(hoverRow isNotNil and: [ aRow = hoverRow and: [ self enabled ] ])
		ifTrue: [ ^ self hoverColor ].
	^ super backgroundColorFor: aRow
]

{ #category : 'event handling' }
OPTHoverHighlightedList >> handleMouseOver: anEvent [

	super handleMouseOver: anEvent.
	self updateHoverRowAt: anEvent position
]

{ #category : 'accessing' }
OPTHoverHighlightedList >> hoverColor [

	^ self theme mouseOverColor
]

{ #category : 'accessing' }
OPTHoverHighlightedList >> hoverRow [

	^ hoverRow
]

{ #category : 'accessing' }
OPTHoverHighlightedList >> hoverRow: aRowOrNil [

	hoverRow = aRowOrNil ifTrue: [ ^ self ].
	hoverRow := aRowOrNil.
	self listMorph changed
]

{ #category : 'event handling' }
OPTHoverHighlightedList >> mouseLeave: anEvent [

	super mouseLeave: anEvent.
	self hoverRow: nil
]

{ #category : 'event handling' }
OPTHoverHighlightedList >> updateHoverRowAt: aPoint [

	| row |
	row := (self scroller bounds containsPoint: aPoint)
		       ifTrue: [ self rowAtLocation: aPoint ]
		       ifFalse: [ 0 ].
	self hoverRow: (row > 0 ifTrue: [ row ])
]
