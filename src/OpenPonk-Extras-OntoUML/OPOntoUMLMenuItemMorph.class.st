"
Menu item with a name, a gray note in a second column (the notes of all items of a menu start at the same place, see OPOntoUMLPopupMenu) and, on the right, the key that does the same on the canvas. Typing in the menu filters by the name only.
"
Class {
	#name : 'OPOntoUMLMenuItemMorph',
	#superclass : 'ToggleMenuItemMorph',
	#instVars : [
		'note',
		'noteOffset',
		'shortcut'
	],
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'drawing' }
OPOntoUMLMenuItemMorph >> drawOn: aCanvas [

	| color |
	super drawOn: aCanvas.
	color := self shouldBeHighlighted
		         ifTrue: [ self selectionTextColor ]
		         ifFalse: [ Color gray ].
	note isEmptyOrNil ifFalse: [
		aCanvas
			drawString: note
			in: (self menuStringBounds left: self menuStringBounds left + self noteOffset)
			font: self fontToUse
			color: color ].
	shortcut isEmptyOrNil ifFalse: [
		aCanvas
			drawString: shortcut
			in: (self menuStringBounds left: self bounds right - (self fontToUse widthOfString: shortcut) - 8)
			font: self fontToUse
			color: color ]
]

{ #category : 'layout' }
OPOntoUMLMenuItemMorph >> minWidth [

	| width |
	width := note isEmptyOrNil
		         ifTrue: [ super minWidth ]
		         ifFalse: [
			         super minWidth - (self fontToUse widthOfString: contents) + self noteOffset
			         + (self fontToUse widthOfString: note) + 10 ].
	shortcut isEmptyOrNil ifTrue: [ ^ width ].
	^ width + (self fontToUse widthOfString: shortcut) + 24
]

{ #category : 'accessing' }
OPOntoUMLMenuItemMorph >> note [

	^ note
]

{ #category : 'accessing' }
OPOntoUMLMenuItemMorph >> note: aStringOrNil [

	note := aStringOrNil
]

{ #category : 'accessing' }
OPOntoUMLMenuItemMorph >> noteOffset [
	"Distance of the note from the start of the name."

	^ noteOffset ifNil: [ (self fontToUse widthOfString: contents) + 16 ]
]

{ #category : 'accessing' }
OPOntoUMLMenuItemMorph >> noteOffset: aNumber [

	noteOffset := aNumber
]

{ #category : 'accessing' }
OPOntoUMLMenuItemMorph >> shortcut [

	^ shortcut
]

{ #category : 'accessing' }
OPOntoUMLMenuItemMorph >> shortcut: aStringOrNil [
	"The key shown on the right, e.g. 'K'."

	shortcut := aStringOrNil
]
