"
A single key on the canvas that chooses a palette tool, e.g. L for Class (see OPOntoUMLStereotypeCatalog class>>#toolShortcuts), in every diagram whose palette has it. The next click on the canvas (or on two elements, for a relation) creates the element; Esc goes back to Select.

Each tool has a subclass, because a Commander shortcut runs a command class.
"
Class {
	#name : 'OPOntoUMLPaletteKeyCommand',
	#superclass : 'CmdCommand',
	#instVars : [
		'diagramController'
	],
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'testing' }
OPOntoUMLPaletteKeyCommand class >> canBeExecutedInContext: aToolContext [

	^ self isAbstract not and: [
		  (aToolContext isKindOf: OPRoassalShapeContext) and: [
			  ((OPDiagramBuilder on: aToolContext diagramController)
				   paletteButton: self paletteLabel
				   ifNone: [ nil ]) isNotNil ] ]
]

{ #category : 'testing' }
OPOntoUMLPaletteKeyCommand class >> isAbstract [

	^ self = OPOntoUMLPaletteKeyCommand
]

{ #category : 'activation' }
OPOntoUMLPaletteKeyCommand class >> keyCombination [

	| shortcut |
	shortcut := OPOntoUMLStereotypeCatalog toolShortcuts detect: [ :each | each first = self paletteLabel ].
	^ shortcut third
		  ifTrue: [ shortcut second shift ]
		  ifFalse: [ shortcut second asKeyCombination ]
]

{ #category : 'accessing' }
OPOntoUMLPaletteKeyCommand class >> paletteLabel [

	^ self subclassResponsibility
]

{ #category : 'accessing' }
OPOntoUMLPaletteKeyCommand >> defaultMenuItemName [

	^ self class paletteLabel
]

{ #category : 'execution' }
OPOntoUMLPaletteKeyCommand >> execute [

	(OPDiagramBuilder on: diagramController) selectPaletteTool: self class paletteLabel
]

{ #category : 'execution' }
OPOntoUMLPaletteKeyCommand >> readParametersFromContext: aToolContext [

	super readParametersFromContext: aToolContext.
	diagramController := aToolContext diagramController
]
