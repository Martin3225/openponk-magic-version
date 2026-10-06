"
End-to-end tests of duplicating selected diagram elements: a real project is opened in a workbench and the command is executed from a canvas context, as the Cmd/Ctrl+D shortcut does.
"
Class {
	#name : 'OPDiagramElementsDuplicatorTest',
	#superclass : 'TestCase',
	#instVars : [
		'workbench',
		'diagramController',
		'undoManager',
		'file'
	],
	#category : 'OpenPonk-Extras-Tests',
	#package : 'OpenPonk-Extras-Tests'
}

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> add: aController [

	diagramController addAsTargetFor: aController onPosition: 100 @ 100.
	^ aController
]

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> add: aController at: aPoint [

	diagramController addAsTargetFor: aController onPosition: aPoint.
	^ aController
]

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> connect: aSourceController to: aTargetController by: anEdgeController [

	aSourceController addAsSourceFor: anEdgeController.
	aTargetController addAsTargetFor: anEdgeController.
	^ anEdgeController
]

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> contextFor: aCollectionOfControllers [

	^ OPRoassalShapeContext
		  for: diagramController canvasPresenter
		  of: (aCollectionOfControllers collect: [ :each | each roassalShape ]) asArray
]

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> controllersOfModelsOfClass: aClass [

	^ (diagramController controllers select: [ :each |
		   each model class == aClass ]) asArray
]

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> duplicate: aCollectionOfControllers [
	"Run the command like the shortcut does and answer controllers of the new selection."

	| context command |
	context := self contextFor: aCollectionOfControllers.
	self assert: (OPDuplicateRoassalShapeCommand canBeExecutedInContext: context).
	command := OPDuplicateRoassalShapeCommand new.
	command readParametersFromContext: context.
	command execute.
	^ self selectedControllers
]

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> erdEntityWithTwoAttributes [
	"Answer { entity. keyAttribute. attribute } connected by transitions."

	| entity key attribute |
	entity := self add: OPErdEntityController new at: 200 @ 150.
	entity model
		name: 'Student';
		isWeak: true.
	key := self add: OPErdKeyAttributeController new at: 120 @ 40.
	key model name: 'id'.
	attribute := self add: OPErdAttributeController new at: 300 @ 40.
	attribute model name: 'jméno'.
	self connect: key to: entity by: OPErdTransitionController new.
	self connect: attribute to: entity by: OPErdTransitionController new.
	^ { entity. key. attribute }
]

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> openModel: aModel [

	workbench := (OPProject new
		              name: 'DuplicateTest';
		              addModel: aModel;
		              yourself) open.
	diagramController := workbench focusedEditor diagramController.
	undoManager := diagramController undoManager
]

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> reloadProject [
	"Save the project to a memory file, close it and open the saved copy."

	| project |
	file := FileSystem memory root / 'duplicate-test.opp'.
	workbench projectController saveProjectTo: file.
	workbench application closeAllWindows.
	project := OPProjectController fromFile: file.
	workbench := project open.
	^ project
]

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> selectedControllers [

	^ (diagramController selectedElements collect: [ :each |
		   diagramController controllerForRoassalShape: each ifNone: [ nil ] ]) asArray
]

{ #category : 'running' }
OPDiagramElementsDuplicatorTest >> tearDown [

	workbench ifNotNil: [ workbench application closeAllWindows ].
	file ifNotNil: [ file ensureDelete ].
	super tearDown
]

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> umlClassNamed: aString in: aPackage [

	^ aPackage packagedElements detect: [ :each |
		  (each isKindOf: OPUMLClass) and: [ each name = aString ] ]
]

{ #category : 'helpers' }
OPDiagramElementsDuplicatorTest >> umlClassesIn: aPackage [

	^ (aPackage packagedElements select: [ :each | each isKindOf: OPUMLClass ]) asArray
]

{ #category : 'tests - command' }
OPDiagramElementsDuplicatorTest >> testCannotBeExecutedOnEmptyCanvas [

	| context |
	self openModel: (OPErd new name: 'erd'; yourself).
	context := OPRoassalShapeContext
		           for: diagramController canvasPresenter
		           of: { diagramController canvas }.
	self deny: (OPDuplicateRoassalShapeCommand canBeExecutedInContext: context)
]

{ #category : 'tests - command' }
OPDiagramElementsDuplicatorTest >> testCommandIsInContextMenuAndOnCmdDAndCtrlD [

	| annotations keys |
	annotations := OPDuplicateRoassalShapeCommand classAnnotations.
	self assert: (annotations anySatisfy: [ :each |
			 (each isKindOf: CmdContextMenuActivation) and: [
				 each annotatedClass == OPDuplicateRoassalShapeCommand ] ]).
	keys := (annotations select: [ :each |
		         each isKindOf: CmdShortcutActivation ]) collect: [ :each |
		        each keyCombination ].
	self assert: (keys includes: $d meta).
	self assert: (keys includes: $d ctrl).
	self assert: OPDuplicateRoassalShapeCommand new defaultMenuItemName equals: 'Duplicate'
]

{ #category : 'tests - command' }
OPDiagramElementsDuplicatorTest >> testKeyboardShortcutsDuplicateSelection [
	"Key events sent to the canvas morph, as when the user presses Cmd+D (Mac) or Ctrl+D."

	| model entity canvasMorph |
	model := OPErd new name: 'erd'; yourself.
	self openModel: model.
	entity := self add: OPErdEntityController new.
	(diagramController canvas propertyAt: OPRSSelectableCanvas)
		selectShapes: (RSGroup with: entity roassalShape)
		byEvent: (RSMouseClick new
				 canvas: diagramController canvas;
				 position: 0 @ 0;
				 yourself).
	canvasMorph := diagramController canvasPresenter adapter widget.

	#( 64 16 ) doWithIndex: [ :modifierButtons :index |
		canvasMorph handleKeyDown: ((KeyboardEvent new
				  setType: #keyDown
				  buttons: modifierButtons
				  position: 0 @ 0
				  keyValue: $d asciiValue
				  charCode: $d asciiValue
				  hand: self currentWorld activeHand
				  stamp: 0)
				 key: (KeyboardKey fromCharacter: $d);
				 yourself).
		self assert: model elements size equals: index + 1.
		self assert: self selectedControllers size equals: 1.
		self deny: self selectedControllers first == entity ]
]

{ #category : 'tests - erd' }
OPDiagramElementsDuplicatorTest >> testErdChildAndEdgesFollowSelectedNodes [

	| model elements copies newEntity newTransitions |
	model := OPErd new name: 'erd'; yourself.
	self openModel: model.
	elements := self erdEntityWithTwoAttributes.

	copies := self duplicate: elements.

	self assert: model elements size equals: 10.
	self assert: copies size equals: 3.
	self assert: (copies noneSatisfy: [ :each | elements includes: each ]).
	newEntity := copies detect: [ :each | each model class == OPErdEntity ].
	self assert: newEntity model name equals: 'Student'.
	self assert: newEntity model isWeak.
	self deny: newEntity model uuid equals: elements first model uuid.
	self assert: newEntity diagramElement bounds position
		equals: elements first diagramElement bounds position + (20 @ 20).
	self assert: newEntity diagramElement bounds extent
		equals: elements first diagramElement bounds extent.
	newTransitions := model elements select: [ :each |
		                  each class == OPErdTransition and: [
			                  each target == newEntity model ] ].
	self
		assert: (newTransitions collect: [ :each | each source name ]) asSet
		equals: #( 'id' 'jméno' ) asSet.
	self assert: (newTransitions allSatisfy: [ :each |
			 copies anySatisfy: [ :copy | copy model == each source ] ])
]

{ #category : 'tests - erd' }
OPDiagramElementsDuplicatorTest >> testErdDuplicateIsOneUndoStep [

	| model elements stackSize |
	model := OPErd new name: 'erd'; yourself.
	self openModel: model.
	elements := self erdEntityWithTwoAttributes.
	stackSize := undoManager undoStack size.

	self duplicate: elements.

	self assert: undoManager undoStack size equals: stackSize + 1.
	self assert: undoManager undoStack last description equals: 'Duplicate'.
	undoManager undo.
	self assert: model elements size equals: 5.
	self assert: diagramController controllers size equals: 5.
	undoManager redo.
	self assert: model elements size equals: 10.
	self assert: ((self controllersOfModelsOfClass: OPErdEntity) allSatisfy: [ :each |
			 each isRendered ]).
	self assert: (self controllersOfModelsOfClass: OPErdEntity) size equals: 2
]

{ #category : 'tests - erd' }
OPDiagramElementsDuplicatorTest >> testErdEdgeNeedsBothEndsDuplicated [

	| model elements |
	model := OPErd new name: 'erd'; yourself.
	self openModel: model.
	elements := self erdEntityWithTwoAttributes.

	self duplicate: { elements first }.

	self assert: model elements size equals: 6.
	self assert: (model elements select: [ :each | each class == OPErdTransition ]) size equals: 2
]

{ #category : 'tests - erd' }
OPDiagramElementsDuplicatorTest >> testErdSaveAndLoadAfterDuplicate [

	| model project loaded uuids |
	model := OPErd new name: 'erd'; yourself.
	self openModel: model.
	self duplicate: self erdEntityWithTwoAttributes.

	project := self reloadProject.

	loaded := project models first.
	self assert: loaded elements size equals: 10.
	uuids := loaded elements collect: [ :each | each uuid ].
	self assert: uuids asSet size equals: 10.
	self
		assert: ((loaded elements select: [ :each | each class == OPErdEntity ])
				 collect: [ :each | each name -> each isWeak ]) asArray
		equals: { 'Student' -> true. 'Student' -> true }
]

{ #category : 'tests - erd' }
OPDiagramElementsDuplicatorTest >> testRepeatedDuplicateDuplicatesTheCopies [

	| model entity first second |
	model := OPErd new name: 'erd'; yourself.
	self openModel: model.
	entity := self add: OPErdEntityController new at: 100 @ 100.

	first := self duplicate: { entity }.
	second := self duplicate: first.

	self assert: (self controllersOfModelsOfClass: OPErdEntity) size equals: 3.
	self assert: second first diagramElement bounds position
		equals: entity diagramElement bounds position + (40 @ 40)
]

{ #category : 'tests - erd' }
OPDiagramElementsDuplicatorTest >> testStyleIsCopiedButNotShared [

	| entity copy |
	self openModel: (OPErd new name: 'erd'; yourself).
	entity := self add: OPErdEntityController new.
	entity diagramElement stylePropertyNamed: #fillColor put: Color red.

	copy := (self duplicate: { entity }) first.

	self assert: (copy diagramElement localStyle at: #fillColor) equals: Color red.
	self deny: copy diagramElement localStyle == entity diagramElement localStyle.
	copy diagramElement stylePropertyNamed: #fillColor put: Color blue.
	self assert: (entity diagramElement localStyle at: #fillColor) equals: Color red
]

{ #category : 'tests - uml' }
OPDiagramElementsDuplicatorTest >> testUmlAssociationIsDuplicatedWithItsEnds [

	| package person address association ends copies newAssociation newEnds newPerson |
	package := OPUMLPackage new name: 'P'; yourself.
	self openModel: package.
	person := self add: OPUmlClassController new at: 100 @ 100.
	person model name: 'Person'.
	address := self add: OPUmlClassController new at: 400 @ 100.
	address model name: 'Address'.
	association := self connect: person to: address by: OPUmlAssociationController new.
	ends := association model memberEnds asArray.
	ends first name: 'resident'.
	ends second
		name: 'homes';
		lowerValue: (OPUMLLiteralInteger new value: 0; yourself);
		upperValue: (OPUMLLiteralUnlimitedNatural new value: '*'; yourself);
		aggregation: OPUMLAggregationKind composite.
	association viewModel writeNavigability: true to: ends second.
	association model applyStereotype: (OntoUMLComponentOf new
			 essential: true;
			 yourself).
	self assert: ends second isNavigable.

	copies := self duplicate: { person. address }.

	self assert: copies size equals: 2.
	newPerson := (copies detect: [ :each | each model name = 'Person' ]) model.
	newAssociation := (package packagedElements select: [ :each |
		                   each isKindOf: OPUMLAssociation ]) detect: [ :each |
		                  each ~~ association model ].
	newEnds := newAssociation memberEnds asArray.
	self
		assert: (newEnds collect: [ :each | each type ]) asArray
		equals: (copies collect: [ :each | each model ]) asArray.
	self assert: newEnds first name equals: 'resident'.
	self assert: newEnds second name equals: 'homes'.
	self assert: newEnds second lowerValue value equals: 0.
	self assert: newEnds second upperValue value equals: '*'.
	self deny: newEnds second upperValue == ends second upperValue.
	self assert: newEnds second aggregation equals: OPUMLAggregationKind composite.
	self assert: newEnds second isNavigable.
	self deny: newEnds first isNavigable.
	self assert: newEnds second owningClass equals: newPerson.
	self
		assert: newPerson ownedAttributes size
		equals: person model ownedAttributes size.
	self assert: newAssociation appliedStereotypes size equals: 1.
	self assert: newAssociation appliedStereotypes first essential.
	self deny: newAssociation appliedStereotypes first
		== association model appliedStereotypes first
]

{ #category : 'tests - uml' }
OPDiagramElementsDuplicatorTest >> testUmlStereotypeDefinitionInAppliedListIsKeptAsReference [
	"OPUmlExamples>>#exampleAlcoholAndBarrel puts a stereotype definition (not an application) into appliedStereotypes."

	| package alcohol definition copy |
	package := OPUMLPackage new name: 'P'; yourself.
	self openModel: package.
	alcohol := self add: OPUmlClassController new.
	definition := OPUMLStereotype new name: 'Liquid'; yourself.
	alcohol model appliedStereotypes add: definition.

	copy := (self duplicate: { alcohol }) first.

	self assert: copy model appliedStereotypes asArray equals: { definition }
]

{ #category : 'tests - uml' }
OPDiagramElementsDuplicatorTest >> testUmlNavigableEndUndoRedo [

	| package person address association controllersBefore newEnd |
	package := OPUMLPackage new name: 'P'; yourself.
	self openModel: package.
	person := self add: OPUmlClassController new at: 100 @ 100.
	address := self add: OPUmlClassController new at: 400 @ 100.
	association := self connect: person to: address by: OPUmlAssociationController new.
	association viewModel writeNavigability: true to: association model memberEnds second.
	controllersBefore := diagramController controllers size.

	self duplicate: { person. address }.
	self assert: diagramController controllers size equals: controllersBefore * 2.
	undoManager undo.
	self assert: diagramController controllers size equals: controllersBefore.
	self assert: (self umlClassesIn: package) size equals: 2.
	undoManager redo.
	self assert: diagramController controllers size equals: controllersBefore * 2.
	newEnd := ((package packagedElements select: [ :each | each isKindOf: OPUMLAssociation ])
		           detect: [ :each | each ~~ association model ]) memberEnds second.
	self assert: newEnd isNavigable.
	self assert: (diagramController controllerForModel: newEnd) isRendered
]

{ #category : 'tests - uml' }
OPDiagramElementsDuplicatorTest >> testUmlAttributeAloneIsDuplicatedIntoItsClass [

	| package person attribute copies |
	package := OPUMLPackage new name: 'P'; yourself.
	self openModel: package.
	person := self add: OPUmlClassController new.
	person model name: 'Person'.
	attribute := OPUmlAttributeController new.
	person addAsTargetFor: attribute.
	attribute model name: 'age'.

	copies := self duplicate: { attribute }.

	self assert: (self umlClassesIn: package) size equals: 1.
	self
		assert: (person model ownedAttributes collect: [ :each | each name ]) asArray
		equals: #( 'age' 'age' ).
	self assert: copies size equals: 1.
	self assert: copies first isRendered
]

{ #category : 'tests - uml' }
OPDiagramElementsDuplicatorTest >> testUmlClassIsDuplicatedWithItsContent [

	| package person address attributes operation copy newClass newAttributes |
	package := OPUMLPackage new name: 'P'; yourself.
	self openModel: package.
	person := self add: OPUmlClassController new at: 100 @ 100.
	person model
		name: 'Person';
		isAbstract: true;
		applyStereotype: OntoUMLKind new.
	person model ownedComments add: (OPUMLComment new body: 'Komentář'; yourself).
	address := self add: OPUmlClassController new at: 400 @ 100.
	address model name: 'Address'.
	attributes := #( 'name' 'home' 'age' ) collect: [ :each |
		              | controller |
		              controller := OPUmlAttributeController new.
		              person addAsTargetFor: controller.
		              controller model name: each.
		              controller ].
	attributes first model
		lowerValue: (OPUMLLiteralInteger new value: 1; yourself);
		upperValue: (OPUMLLiteralUnlimitedNatural new value: 5; yourself).
	attributes second model type: address model.
	operation := OPUmlOperationController new.
	person addAsTargetFor: operation.
	operation model name: 'greet'.
	operation model ownedParameters add: (OPUMLParameter new
			 name: 'who';
			 type: address model;
			 yourself).

	copy := (self duplicate: { person }) first.

	newClass := copy model.
	self deny: newClass == person model.
	self assert: newClass name equals: 'Person'.
	self assert: newClass isAbstract.
	newAttributes := newClass ownedAttributes asArray.
	self
		assert: (newAttributes collect: [ :each | each name ])
		equals: #( 'name' 'home' 'age' ).
	self assert: newAttributes first lowerValue value equals: 1.
	self assert: newAttributes first upperValue value equals: 5.
	self deny: newAttributes first lowerValue == attributes first model lowerValue.
	self assert: newAttributes second type equals: address model.
	self assert: (newAttributes allSatisfy: [ :each |
			 (diagramController controllerForModel: each) isRendered ]).
	self assert: newClass ownedOperations size equals: 1.
	self
		assert: (newClass ownedOperations first ownedParameters collect: [ :each |
				 each name -> each type ]) asArray
		equals: { 'who' -> address model }.
	self deny: newClass ownedOperations first ownedParameters first
		== operation model ownedParameters first.
	self
		assert: (newClass ownedComments collect: [ :each | each body ]) asArray
		equals: #( 'Komentář' ).
	self assert: (newClass appliedStereotypes collect: [ :each | each class ]) asArray
		equals: { OntoUMLKind }.
	self deny: newClass appliedStereotypes first == person model appliedStereotypes first.
	self assert: person model ownedAttributes size equals: 3
]

{ #category : 'tests - uml' }
OPDiagramElementsDuplicatorTest >> testUmlSaveAndLoadAfterDuplicate [

	| package person attribute project loaded classes |
	package := OPUMLPackage new name: 'P'; yourself.
	self openModel: package.
	person := self add: OPUmlClassController new.
	person model name: 'Person'.
	attribute := OPUmlAttributeController new.
	person addAsTargetFor: attribute.
	attribute model name: 'age'.
	self duplicate: { person }.

	project := self reloadProject.

	loaded := project models first.
	classes := self umlClassesIn: loaded.
	self assert: classes size equals: 2.
	self assert: (classes collect: [ :each | each uuid ]) asSet size equals: 2.
	self assert: (classes allSatisfy: [ :each |
			 each name = 'Person' and: [
				 (each ownedAttributes collect: [ :attr | attr name ]) asArray = #( 'age' ) ] ])
]

{ #category : 'tests - uml' }
OPDiagramElementsDuplicatorTest >> testUmlSelectedOwnerAndChildAreDuplicatedOnce [

	| package person attribute copies |
	package := OPUMLPackage new name: 'P'; yourself.
	self openModel: package.
	person := self add: OPUmlClassController new.
	person model name: 'Person'.
	attribute := OPUmlAttributeController new.
	person addAsTargetFor: attribute.
	attribute model name: 'age'.

	copies := self duplicate: { person. attribute }.

	self assert: copies size equals: 1.
	self assert: person model ownedAttributes size equals: 1.
	self assert: copies first model ownedAttributes size equals: 1
]
