"
A menu popped up at the mouse (or, from a keyboard shortcut, over the canvas) for the selected diagram elements. Typing narrows the items down (as in every Pharo menu); arrows and Enter choose.

Items show a name and, in gray, a short explanation, so the menu doubles as a cheat sheet.
"
Class {
	#name : 'OPOntoUMLPopupMenu',
	#superclass : 'Object',
	#instVars : [
		'diagramController',
		'controllers'
	],
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'testing' }
OPOntoUMLPopupMenu class >> isAbstract [

	^ self = OPOntoUMLPopupMenu
]

{ #category : 'building' }
OPOntoUMLPopupMenu >> addGroupLabel: aString to: aMenu [

	aMenu add: aString target: nil selector: nil.
	aMenu lastItem isEnabled: false
]

{ #category : 'building' }
OPOntoUMLPopupMenu >> addItem: aName note: aNoteOrNil icon: aFormOrNil to: aMenu selector: aSelector arguments: anArray [

	| item |
	item := OPOntoUMLMenuItemMorph new
		        contents: aName;
		        note: aNoteOrNil;
		        target: self;
		        selector: aSelector;
		        arguments: anArray;
		        yourself.
	aFormOrNil ifNotNil: [ item icon: aFormOrNil ].
	aMenu addMenuItem: item
]

{ #category : 'building' }
OPOntoUMLPopupMenu >> alignNotesOf: aMenu [
	"Start the notes of all items at the same place, after the longest name."

	| items offset |
	items := aMenu items select: [ :each | each isKindOf: OPOntoUMLMenuItemMorph ].
	items ifEmpty: [ ^ aMenu ].
	offset := (items inject: 0 into: [ :max :each |
		           max max: (each fontToUse widthOfString: each contents) ]) + 20.
	items do: [ :each | each noteOffset: offset ].
	^ aMenu
]

{ #category : 'building' }
OPOntoUMLPopupMenu >> buildMenu [
	"A MenuMorph, or nil when there is nothing to offer for the selection (the user has been told why)."

	^ self subclassResponsibility
]

{ #category : 'accessing' }
OPOntoUMLPopupMenu >> controllers [

	^ controllers
]

{ #category : 'accessing' }
OPOntoUMLPopupMenu >> controllers: aCollection [

	controllers := aCollection asArray
]

{ #category : 'accessing' }
OPOntoUMLPopupMenu >> diagramController [

	^ diagramController
]

{ #category : 'accessing' }
OPOntoUMLPopupMenu >> diagramController: aDiagramController [

	diagramController := aDiagramController
]

{ #category : 'private' }
OPOntoUMLPopupMenu >> inform: aString [

	UIManager default inform: aString
]

{ #category : 'showing' }
OPOntoUMLPopupMenu >> popUp [

	| menu world hand |
	menu := self buildMenu ifNil: [ ^ nil ].
	self alignNotesOf: menu.
	world := self currentWorld.
	hand := world activeHand.
	menu
		popUpAt: self popUpPosition
		forHand: hand
		in: world
		allowKeyboard: true.
	^ menu
]

{ #category : 'showing' }
OPOntoUMLPopupMenu >> popUpPosition [
	"Where the mouse is, when it is over the canvas (a context menu); otherwise (a keyboard shortcut) a bit inside the canvas."

	| handPosition morph |
	handPosition := self currentWorld activeHand position.
	morph := diagramController canvas morph ifNil: [ ^ handPosition ].
	^ (morph bounds containsPoint: handPosition)
		  ifTrue: [ handPosition ]
		  ifFalse: [ morph bounds topLeft + (40 @ 40) ]
]
