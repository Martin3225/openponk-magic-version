"
Duplicates all top-level nodes of every example model shipped with the OpenPonk plugins and checks that the diagram doubles, that undo and redo restore it and that the project saves and loads to the same picture.
"
Class {
	#name : 'OPDuplicateExamplesTest',
	#superclass : 'TestCase',
	#category : 'OpenPonk-Extras-Tests',
	#package : 'OpenPonk-Extras-Tests'
}

{ #category : 'accessing' }
OPDuplicateExamplesTest class >> defaultTimeLimit [

	^ 30 minutes
]

{ #category : 'accessing' }
OPDuplicateExamplesTest >> exampleClassNames [

	^ #( #OPBPMNExamples #OPBormExamples #OPDemoExamples #OPErdExamples
	     #OPFsmExamples #OPMcExamples #OPPetriNetsExamples #OPUmlExamples
	     #OntoUMLExamples )
]

{ #category : 'accessing' }
OPDuplicateExamplesTest >> examplesThatCannotBeSaved [
	"Saving fails even without duplicating (a stereotype definition in appliedStereotypes breaks the XMI writer)."

	^ #( #exampleAlcoholAndBarrel )
]

{ #category : 'accessing' }
OPDuplicateExamplesTest >> examples [

	^ (self exampleClassNames
		   select: [ :each | Smalltalk hasClassNamed: each ]
		   thenCollect: [ :each | Smalltalk at: each ]) flatCollect: [ :each |
		  ((each class selectors select: [ :selector |
			    (selector beginsWith: 'example') and: [
				    (self skippedExamples includes: selector) not ] ])
			   asSortedCollection) collect: [ :selector | each -> selector ] ]
]

{ #category : 'running' }
OPDuplicateExamplesTest >> problemsOfExample: anAssociation [

	| workbench reloaded diagramController before nodes context command shapes file problems |
	problems := OrderedCollection new.
	[
	workbench := (OPProject new
		              name: 'Examples';
		              addModel: (anAssociation key perform: anAssociation value);
		              yourself) open.
	workbench showAllElementsInAllDiagrams.
	diagramController := workbench focusedEditor diagramController.
	before := diagramController controllers size.
	nodes := (diagramController controllers select: [ :each |
		          each diagramElement isNotNil and: [
			          each diagramElement isEdge not and: [
				          each diagramElement owningElement
				          == diagramController diagramElement ] ] ]) asArray.
	context := OPRoassalShapeContext
		           for: diagramController canvasPresenter
		           of: (nodes collect: [ :each | each roassalShape ]).
	command := OPDuplicateRoassalShapeCommand new.
	command readParametersFromContext: context.
	command execute.
	diagramController controllers size = (2 * before) ifFalse: [
		problems add: 'duplicate gave ' , diagramController controllers size printString
			, ' controllers instead of ' , (2 * before) printString ].
	diagramController undoManager undo.
	diagramController controllers size = before ifFalse: [
		problems add: 'undo left ' , diagramController controllers size printString ].
	diagramController undoManager redo.
	diagramController controllers size = (2 * before) ifFalse: [
		problems add: 'redo gave ' , diagramController controllers size printString ].
	(self examplesThatCannotBeSaved includes: anAssociation value) ifTrue: [
		workbench application closeAllWindows.
		^ problems ].
	shapes := diagramController canvas shapes
		          collect: [ :each | each class ]
		          as: Bag.
	file := FileSystem memory root / 'examples.opp'.
	workbench projectController saveProjectTo: file.
	reloaded := (OPProjectController fromFile: file) open.
	reloaded showAllElementsInAllDiagrams.
	(reloaded focusedEditor canvasPresenter canvas shapes
		 collect: [ :each | each class ]
		 as: Bag) = shapes ifFalse: [
		problems add: 'saved and loaded diagram differs' ] ]
		on: Error
		do: [ :error | problems add: error class name , ': ' , error messageText asString ].
	workbench ifNotNil: [ workbench application closeAllWindows ].
	reloaded ifNotNil: [ reloaded application closeAllWindows ].
	^ problems
]

{ #category : 'accessing' }
OPDuplicateExamplesTest >> skippedExamples [
	"exampleEmpty has nothing to duplicate, exampleERDsample answers a workbench instead of a model, and in exampleSecurityProfile OpenPonk itself does not show the base_ end of a newly created stereotype extension until the project is reloaded (the same happens when drawing an extension from the palette)."

	^ #( #exampleEmpty #exampleERDsample #exampleSecurityProfile )
]

{ #category : 'tests' }
OPDuplicateExamplesTest >> testDuplicateAllNodesOfEveryExample [

	| failures |
	failures := OrderedCollection new.
	self examples do: [ :each |
		(self problemsOfExample: each) ifNotEmpty: [ :problems |
			failures add: each value , ': ' , (', ' join: problems) ] ].
	self assert: failures isEmpty description: [ String cr join: failures ].
	self assert: self examples size > 20
]
