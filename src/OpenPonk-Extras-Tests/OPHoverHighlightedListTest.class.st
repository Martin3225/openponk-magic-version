"
Tests hover highlight of drop-down popup lists using mouse events sent through the world's hand, the same path real mouse movement takes.
"
Class {
	#name : 'OPHoverHighlightedListTest',
	#superclass : 'TestCase',
	#instVars : [
		'list',
		'items',
		'selectedIndex'
	],
	#category : 'OpenPonk-Extras-Tests',
	#package : 'OpenPonk-Extras-Tests'
}

{ #category : 'model' }
OPHoverHighlightedListTest >> items [

	^ items
]

{ #category : 'helpers' }
OPHoverHighlightedListTest >> moveHandTo: aPoint [

	| hand event |
	hand := self currentWorld activeHand.
	event := MouseMoveEvent basicNew
		         setType: #mouseMove
		         startPoint: hand position
		         endPoint: aPoint
		         trail: { hand position. aPoint }
		         buttons: 0
		         hand: hand
		         stamp: Time millisecondClockValue.
	hand handleEvent: event
]

{ #category : 'helpers' }
OPHoverHighlightedListTest >> pointOfRow: aRow [
	"Answer the middle of the vertical span that the list itself maps to aRow."

	| x ys |
	x := list scroller bounds center x.
	ys := (list scroller top to: list scroller bottom) select: [ :y |
		      (list rowAtLocation: x @ y) = aRow ].
	self deny: ys isEmpty.
	^ x @ (ys first + ys last // 2)
]

{ #category : 'model' }
OPHoverHighlightedListTest >> selectedIndex [

	^ selectedIndex
]

{ #category : 'model' }
OPHoverHighlightedListTest >> selectedIndex: anInteger [

	selectedIndex := anInteger
]

{ #category : 'running' }
OPHoverHighlightedListTest >> setUp [

	super setUp.
	items := #( 'alpha' 'beta' 'gamma' 'delta' ).
	selectedIndex := 1.
	list := (OPHoverListMorph
		         on: self
		         list: #items
		         selected: #selectedIndex
		         changeSelected: #selectedIndex:
		         menu: nil
		         keystroke: nil)
		        position: 20 @ 20;
		        extent: 150 @ 90;
		        yourself.
	list openInWorld.
	self currentWorld doOneCycleNow
]

{ #category : 'running' }
OPHoverHighlightedListTest >> tearDown [

	list ifNotNil: [ list delete ].
	self moveHandTo: 0 @ 0.
	super tearDown
]

{ #category : 'tests' }
OPHoverHighlightedListTest >> testDropListsUseHoverLists [

	self assert: SpDropListMorph new listMorphClass equals: OPHoverIconListMorph.
	self assert: EditableDropListMorph new listMorphClass equals: OPHoverListMorph.
	self assert: OPEditableDropListMorph new listMorphClass equals: OPHoverListMorph.
	self assert: (OPHoverIconListMorph inheritsFrom: PluggableIconListMorph)
]

{ #category : 'tests' }
OPHoverHighlightedListTest >> testHoverFollowsMouse [

	self moveHandTo: (self pointOfRow: 3).
	self assert: list hoverRow equals: 3.
	self assert: (list backgroundColorFor: 3) equals: list hoverColor.
	self deny: (list backgroundColorFor: 2) = list hoverColor.

	self moveHandTo: (self pointOfRow: 2).
	self assert: list hoverRow equals: 2
]

{ #category : 'tests' }
OPHoverHighlightedListTest >> testHoverIsClearedWhenMouseLeaves [

	self moveHandTo: (self pointOfRow: 2).
	self assert: list hoverRow equals: 2.

	self moveHandTo: list bounds bottomRight + (40 @ 40).
	self assert: list hoverRow isNil.
	self deny: (list backgroundColorFor: 2) = list hoverColor
]
