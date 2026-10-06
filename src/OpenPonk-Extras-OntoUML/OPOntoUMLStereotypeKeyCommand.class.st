"
A single key on the canvas of an OntoUML diagram, e.g. K for Kind (see OPOntoUMLStereotypeCatalog class>>#shortcuts):

- with classes selected, it sets their stereotype (one undoable step; relations and other elements in the selection are left as they are);
- otherwise it chooses the palette tool of the stereotype, so that the next click on the canvas creates such a class.

Each stereotype has a subclass, because a Commander shortcut runs a command class.
"
Class {
	#name : 'OPOntoUMLStereotypeKeyCommand',
	#superclass : 'CmdCommand',
	#instVars : [
		'diagramController',
		'controllers'
	],
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'testing' }
OPOntoUMLStereotypeKeyCommand class >> canBeExecutedInContext: aToolContext [

	^ self isAbstract not and: [
		  (aToolContext isKindOf: OPRoassalShapeContext) and: [
			  OPOntoUMLStereotypeCatalog isOntoUMLDiagram: aToolContext diagramController ] ]
]

{ #category : 'testing' }
OPOntoUMLStereotypeKeyCommand class >> isAbstract [

	^ self = OPOntoUMLStereotypeKeyCommand
]

{ #category : 'activation' }
OPOntoUMLStereotypeKeyCommand class >> keyCombination [

	| shortcut |
	shortcut := OPOntoUMLStereotypeCatalog shortcuts detect: [ :each | each first = self stereotypeName ].
	^ shortcut third
		  ifTrue: [ shortcut second shift ]
		  ifFalse: [ shortcut second asKeyCombination ]
]

{ #category : 'accessing' }
OPOntoUMLStereotypeKeyCommand class >> stereotypeName [

	^ self subclassResponsibility
]

{ #category : 'accessing' }
OPOntoUMLStereotypeKeyCommand >> defaultMenuItemName [

	^ self class stereotypeName
]

{ #category : 'execution' }
OPOntoUMLStereotypeKeyCommand >> execute [

	| classes |
	classes := controllers select: [ :each | each model class == OPUMLClass ].
	classes ifEmpty: [
		^ (OPDiagramBuilder on: diagramController) selectPaletteTool: self class stereotypeName ].
	OPOntoUMLStereotypeMenu new
		diagramController: diagramController;
		controllers: classes;
		applyStereotypeNamed: self class stereotypeName
]

{ #category : 'execution' }
OPOntoUMLStereotypeKeyCommand >> readParametersFromContext: aToolContext [

	super readParametersFromContext: aToolContext.
	diagramController := aToolContext diagramController.
	controllers := aToolContext controllers
]
