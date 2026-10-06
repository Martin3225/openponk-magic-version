"
Common setup of the OntoUML assistant tests: a real OntoUML project opened in a workbench, elements created through OPDiagramBuilder as the palette creates them, Czech texts.
"
Class {
	#name : 'OPOntoUMLAssistantTestCase',
	#superclass : 'TestCase',
	#instVars : [
		'workbench',
		'diagramController',
		'builder',
		'nextX',
		'language'
	],
	#category : 'OpenPonk-Extras-OntoUML-Tests',
	#package : 'OpenPonk-Extras-OntoUML-Tests'
}

{ #category : 'testing' }
OPOntoUMLAssistantTestCase class >> isAbstract [

	^ self = OPOntoUMLAssistantTestCase
]

{ #category : 'accessing' }
OPOntoUMLAssistantTestCase class >> defaultTimeLimit [

	^ 2 minutes
]

{ #category : 'helpers' }
OPOntoUMLAssistantTestCase >> class: aStereotypeName named: aString [

	nextX := nextX + 160.
	^ builder
		  createNode: aStereotypeName
		  in: nil
		  topLeft: nextX @ 100
		  named: aString
]

{ #category : 'helpers' }
OPOntoUMLAssistantTestCase >> connect: aSource to: aTarget by: aType [

	^ builder
		  connect: aType
		  from: aSource
		  to: aTarget
		  named: nil
]

{ #category : 'helpers' }
OPOntoUMLAssistantTestCase >> contextFor: aCollectionOfControllers [

	^ OPRoassalShapeContext
		  for: diagramController canvasPresenter
		  of: (aCollectionOfControllers collect: [ :each | each roassalShape ]) asArray
]

{ #category : 'helpers' }
OPOntoUMLAssistantTestCase >> generalize: aChild to: aParent [

	^ self connect: aChild to: aParent by: 'Generalization'
]

{ #category : 'helpers' }
OPOntoUMLAssistantTestCase >> menusInWorld [

	^ self currentWorld submorphs select: [ :each | each isKindOf: MenuMorph ]
]

{ #category : 'helpers' }
OPOntoUMLAssistantTestCase >> openOntoUML [

	| model |
	model := OntoUMLPlugin new newModel.
	model name: 'Assistant test'.
	self openModel: model
]

{ #category : 'helpers' }
OPOntoUMLAssistantTestCase >> openModel: aModel [

	workbench := (OPProject new
		              name: 'OntoUML assistant test';
		              addModel: aModel;
		              yourself) open.
	diagramController := workbench focusedEditor diagramController.
	builder := OPDiagramBuilder on: diagramController
]

{ #category : 'helpers' }
OPOntoUMLAssistantTestCase >> pressKey: aCharacter withModifier: modifierButtons [

	diagramController canvasPresenter adapter widget handleKeyDown: ((KeyboardEvent new
			  setType: #keyDown
			  buttons: modifierButtons
			  position: 0 @ 0
			  keyValue: aCharacter asciiValue
			  charCode: aCharacter asciiValue
			  hand: self currentWorld activeHand
			  stamp: 0)
			 key: (KeyboardKey fromCharacter: aCharacter);
			 yourself)
]

{ #category : 'helpers' }
OPOntoUMLAssistantTestCase >> select: aCollectionOfControllers [

	(diagramController canvas propertyAt: OPRSSelectableCanvas)
		selectShapes: (RSGroup withAll: (aCollectionOfControllers collect: [ :each | each roassalShape ]))
		byEvent: (RSMouseClick new
				 canvas: diagramController canvas;
				 position: 0 @ 0;
				 yourself)
]

{ #category : 'running' }
OPOntoUMLAssistantTestCase >> setUp [

	super setUp.
	nextX := 0.
	language := OPOntoUMLTexts language.
	OPOntoUMLTexts language: #cs
]

{ #category : 'helpers' }
OPOntoUMLAssistantTestCase >> stereotypeOf: aController [

	^ OPOntoUMLStereotypeCatalog stereotypeNameOf: aController model
]

{ #category : 'running' }
OPOntoUMLAssistantTestCase >> tearDown [

	self menusInWorld do: [ :each | each delete ].
	workbench ifNotNil: [ workbench application closeAllWindows ].
	OPOntoUMLTexts language: language.
	super tearDown
]
