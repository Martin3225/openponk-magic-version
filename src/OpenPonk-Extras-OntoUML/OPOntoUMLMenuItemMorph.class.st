"
Menu item with a name and a gray note in a second column (the notes of all items of a menu start at the same place, see OPOntoUMLPopupMenu). Typing in the menu filters by the name only.
"
Class {
	#name : 'OPOntoUMLMenuItemMorph',
	#superclass : 'ToggleMenuItemMorph',
	#instVars : [
		'note',
		'noteOffset'
	],
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'drawing' }
OPOntoUMLMenuItemMorph >> drawOn: aCanvas [

	super drawOn: aCanvas.
	note isEmptyOrNil ifTrue: [ ^ self ].
	aCanvas
		drawString: note
		in: (self menuStringBounds left: self menuStringBounds left + self noteOffset)
		font: self fontToUse
		color: (self shouldBeHighlighted
				 ifTrue: [ self selectionTextColor ]
				 ifFalse: [ Color gray ])
]

{ #category : 'layout' }
OPOntoUMLMenuItemMorph >> minWidth [

	note isEmptyOrNil ifTrue: [ ^ super minWidth ].
	^ super minWidth - (self fontToUse widthOfString: contents) + self noteOffset
	  + (self fontToUse widthOfString: note) + 10
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
