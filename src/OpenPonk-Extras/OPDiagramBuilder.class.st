"
I build and change diagrams the way the user does in the editor:

- elements are created from the entries of the diagram's palette, so they get the same model, view model, shape and, for stereotyped entries such as those of OntoUML, the same stereotype;
- edges are connected through the controllers, which check what may be connected;
- stereotypes and generalization sets are changed by undoable commands.

I do not open undo transactions myself; callers group my steps with #inTransactionLabeled:do:. Problems are signalled as OPDiagramBuildError with a message meant for the user.

Used by the MCP server, the OntoUML text import and editor commands.
"
Class {
	#name : 'OPDiagramBuilder',
	#superclass : 'Object',
	#instVars : [
		'diagramController',
		'paletteEntries'
	],
	#category : 'OpenPonk-Extras-Builder',
	#package : 'OpenPonk-Extras',
	#tag : 'Builder'
}

{ #category : 'instance creation' }
OPDiagramBuilder class >> on: aDiagramController [

	^ self new
		  diagramController: aDiagramController;
		  yourself
]

{ #category : 'stereotypes' }
OPDiagramBuilder >> applyStereotype: aStereotypeOrNil to: aController [
	"Replace the stereotypes of the element by aStereotypeOrNil (a stereotype of a profile applied to the diagram's model, see #stereotypes); nil removes them. Undoable."

	| model viewModel previous |
	model := aController model.
	viewModel := aController viewModel.
	(self canHaveStereotypes: aController) ifFalse: [
		OPDiagramBuildError signal: (self describe: aController) , ' cannot have stereotypes' ].
	previous := model appliedStereotypes copy.
	self execute: (OPBlockCommand
			 named: 'Change stereotype'
			 execute: [
				 aStereotypeOrNil
					 ifNil: [ viewModel removeStereotypesIn: model ]
					 ifNotNil: [ viewModel applyStereotype: aStereotypeOrNil to: model ].
				 self refresh: aController ]
			 undo: [
				 viewModel removeStereotypesIn: model.
				 previous do: [ :each | model applyStereotype: each ].
				 self refresh: aController ])
]

{ #category : 'stereotypes' }
OPDiagramBuilder >> canHaveStereotypes: aController [

	^ (aController model respondsTo: #appliedStereotypes) and: [
		  aController viewModel respondsTo: #applyStereotype:to: ]
]

{ #category : 'private' }
OPDiagramBuilder >> complete: aController by: aPaletteEntry [
	"What the palette tool does after creating an element (OntoUML entries apply their stereotype here)."

	(aPaletteEntry at: #onComplete) ifNotNil: [ :block | block cull: aController ]
]

{ #category : 'creating' }
OPDiagramBuilder >> connect: aLabel from: aSourceController to: aTargetController named: aNameOrNil [
	"Create an edge of the palette entry aLabel, e.g. 'Generalization' or 'Mediation'."

	| entry edge |
	entry := self paletteEntry: aLabel.
	(entry at: #kind) = 'edge' ifFalse: [
		OPDiagramBuildError signal: '"' , (entry at: #label) , '" is not a relationship type' ].
	edge := (entry at: #factory) value.
	(aSourceController canBeSourceFor: edge) ifFalse: [
		OPDiagramBuildError signal:
			(self describe: aSourceController) , ' cannot be the source of ' , (entry at: #label) ].
	"Only remembers the source; validity of the target may depend on it (e.g. in ER diagrams)."
	aSourceController addAsSourceFor: edge.
	(aTargetController canBeTargetFor: edge) ifFalse: [
		OPDiagramBuildError signal: (self describe: aTargetController) , ' cannot be the target of '
			, (entry at: #label) , ' from ' , (self describe: aSourceController) ].
	aTargetController addAsTargetFor: edge.
	self complete: edge by: entry.
	aNameOrNil ifNotNil: [ self rename: edge to: aNameOrNil ].
	^ edge
]

{ #category : 'creating' }
OPDiagramBuilder >> createNode: aLabel in: aParentControllerOrNil topLeft: aPointOrNil named: aNameOrNil [
	"Create an element of the palette entry aLabel (e.g. 'Class', 'Kind') in the diagram or inside a parent element; aPointOrNil is the top-left corner of the shape (ignored for elements laid out by their parent)."

	| entry controller parent position |
	entry := self paletteEntry: aLabel.
	(entry at: #kind) = 'node' ifFalse: [
		OPDiagramBuildError signal: '"' , (entry at: #label) , '" is a relationship type' ].
	controller := (entry at: #factory) value.
	parent := aParentControllerOrNil ifNil: [ diagramController ].
	(parent canBeTargetFor: controller) ifFalse: [
		OPDiagramBuildError signal: (parent == diagramController
				 ifTrue: [ '"' , (entry at: #label) , '" must be created inside a parent element' ]
				 ifFalse: [ '"' , (entry at: #label) , '" cannot be created inside ' , (self describe: parent) ]) ].
	position := parent == diagramController ifTrue: [ aPointOrNil ].
	parent addAsTargetFor: controller onPosition: position.
	position ifNotNil: [ self placeTopLeftOf: controller diagramElement at: position ].
	self complete: controller by: entry.
	aNameOrNil ifNotNil: [ self rename: controller to: aNameOrNil ].
	^ controller
]

{ #category : 'naming' }
OPDiagramBuilder >> describe: aController [
	"E.g. Class 'Person' (with double quotes around the name)."

	^ (self typeNameOf: aController) , ' "' , ((self nameOf: aController model) ifNil: [ '' ]) , '"'
]

{ #category : 'accessing' }
OPDiagramBuilder >> diagramController [

	^ diagramController
]

{ #category : 'accessing' }
OPDiagramBuilder >> diagramController: aDiagramController [

	diagramController := aDiagramController
]

{ #category : 'geometry' }
OPDiagramBuilder >> displayedRectangleOf: aDiagramElement [
	"The rendered shape when there is one (some shapes size themselves to their content), otherwise the stored bounds."

	| bounds |
	(aDiagramElement isRendered and: [ aDiagramElement roassalShape isNotNil ]) ifTrue: [
		^ aDiagramElement roassalShape encompassingRectangle ].
	bounds := [ aDiagramElement bounds ]
		          on: Error
		          do: [ nil ].
	bounds ifNil: [ ^ nil ].
	^ Rectangle center: bounds position extent: bounds extent
]

{ #category : 'commands' }
OPDiagramBuilder >> execute: aCommand [

	diagramController undoManager
		ifNil: [ aCommand execute ]
		ifNotNil: [ :undoManager | undoManager execute: aCommand ]
]

{ #category : 'generalization sets' }
OPDiagramBuilder >> generalizationSet: aSet disjoint: isDisjoint covering: isCovering [
	"Change the constraints of an existing set. Undoable."

	| command |
	command := self newGeneralizationSetsCommandFor: aSet generalizations.
	command
		recordPropertyChangeOn: aSet
		oldName: aSet name
		newName: aSet name
		oldIsCovering: aSet isCovering
		newIsCovering: isCovering
		oldIsDisjoint: aSet isDisjoint
		newIsDisjoint: isDisjoint.
	self execute: command.
	^ aSet
]

{ #category : 'generalization sets' }
OPDiagramBuilder >> addGeneralizations: aCollectionOfGeneralizations toSet: aSet [
	"Undoable."

	| command |
	command := self newGeneralizationSetsCommandFor: aCollectionOfGeneralizations.
	command recordMembershipChangeOn: aSet added: aCollectionOfGeneralizations asArray removed: #(  ).
	self execute: command.
	^ aSet
]

{ #category : 'generalization sets' }
OPDiagramBuilder >> removeGeneralizations: aCollectionOfGeneralizations fromSet: aSet [
	"Undoable. A set left without generalizations is removed from the model."

	| command remaining |
	command := self newGeneralizationSetsCommandFor: aCollectionOfGeneralizations.
	remaining := aSet generalizations reject: [ :each | aCollectionOfGeneralizations includes: each ].
	remaining
		ifEmpty: [
			command
				recordRemoveSet: aSet
				fromPackage: diagramController model
				generalizations: aSet generalizations asArray ]
		ifNotEmpty: [
			command recordMembershipChangeOn: aSet added: #(  ) removed: aCollectionOfGeneralizations asArray ].
	self execute: command
]

{ #category : 'commands' }
OPDiagramBuilder >> inTransactionLabeled: aString do: aBlock [

	^ diagramController undoManager
		  ifNil: [ aBlock value ]
		  ifNotNil: [ :undoManager | undoManager inTransactionLabeled: aString do: aBlock ]
]

{ #category : 'naming' }
OPDiagramBuilder >> nameOf: aModel [

	| name |
	(aModel respondsTo: #name) ifFalse: [ ^ nil ].
	name := [ aModel name ]
		        on: Error
		        do: [ nil ].
	^ name ifNotNil: [ name asString ]
]

{ #category : 'generalization sets' }
OPDiagramBuilder >> newGeneralizationSetOf: aCollectionOfGeneralizations disjoint: isDisjoint covering: isCovering named: aNameOrNil [
	"Group generalizations with the same general element into a new set owned by the diagram's package. Undoable."

	| generals package set command |
	aCollectionOfGeneralizations ifEmpty: [
		OPDiagramBuildError signal: 'A generalization set needs at least one generalization' ].
	(aCollectionOfGeneralizations allSatisfy: [ :each | each isKindOf: OPUMLGeneralization ])
		ifFalse: [ OPDiagramBuildError signal: 'All elements must be generalizations' ].
	generals := (aCollectionOfGeneralizations collect: [ :each | each general ]) asSet.
	generals size = 1 ifFalse: [
		OPDiagramBuildError signal: 'The generalizations must have the same general element' ].
	package := diagramController model.
	(package respondsTo: #packagedElements) ifFalse: [
		OPDiagramBuildError signal: 'The diagram has no package to own the set' ].
	set := OPUMLGeneralizationSet new.
	set
		name: aNameOrNil;
		isDisjoint: isDisjoint;
		isCovering: isCovering.
	command := self newGeneralizationSetsCommandFor: aCollectionOfGeneralizations.
	command
		recordAddSet: set toPackage: package;
		recordMembershipChangeOn: set added: aCollectionOfGeneralizations asArray removed: #(  ).
	self execute: command.
	^ set
]

{ #category : 'generalization sets' }
OPDiagramBuilder >> newGeneralizationSetsCommandFor: aCollectionOfGeneralizations [

	^ OPUmlUpdateGeneralizationSetsCommand new
		  viewModelRegistry: diagramController viewModelRegistry;
		  affectedGeneralizations: aCollectionOfGeneralizations;
		  yourself
]

{ #category : 'palette' }
OPDiagramBuilder >> paletteEntries [
	"Creation entries of the diagram's palette as dictionaries with #label, #kind ('node' or 'edge'), #factory and #onComplete (run after creation, e.g. applies the stereotype of OntoUML entries)."

	^ paletteEntries ifNil: [ paletteEntries := self readPaletteEntries ]
]

{ #category : 'palette' }
OPDiagramBuilder >> paletteEntry: aLabel [

	^ self paletteEntry: aLabel ifNone: [
		  OPDiagramBuildError signal: 'Unknown element type "' , aLabel asString , '". Types: '
			  , (', ' join: (self paletteEntries collect: [ :each | each at: #label ])) ]
]

{ #category : 'palette' }
OPDiagramBuilder >> paletteEntry: aLabel ifNone: aBlock [

	^ self paletteEntries
		  detect: [ :each | (each at: #label) asLowercase = aLabel asString asLowercase ]
		  ifNone: aBlock
]

{ #category : 'palette' }
OPDiagramBuilder >> paletteEntryOf: anEntry [
	"The tool of some entries is only referenced from their button action, so look there too."

	| tool action kind |
	tool := anEntry tool.
	(tool isNil and: [ (action := anEntry action) isNotNil ]) ifTrue: [
		tool := ((1 to: action basicSize) collect: [ :index | action basicAt: index ])
			        detect: [ :each |
				        (each isKindOf: OPCreationTool) or: [
					        each isKindOf: OPConnectionCreationTool ] ]
			        ifNone: [ nil ] ].
	(tool isKindOf: OPCreationTool) ifTrue: [ kind := 'node' ].
	(tool isKindOf: OPConnectionCreationTool) ifTrue: [ kind := 'edge' ].
	(kind isNil or: [ anEntry label isEmptyOrNil ]) ifTrue: [ ^ nil ].
	^ Dictionary new
		  at: #label put: anEntry label asString;
		  at: #kind put: kind;
		  at: #factory put: (tool instVarNamed: #factory);
		  at: #onComplete put: (tool instVarNamed: #onComplete);
		  yourself
]

{ #category : 'geometry' }
OPDiagramBuilder >> placeTopLeftOf: aDiagramElement at: aPoint [
	"Move the shape so that its drawn top-left corner is at aPoint (directly; for freshly created elements)."

	| delta |
	delta := self topLeftCorrectionOf: aDiagramElement to: aPoint.
	delta = (0 @ 0) ifTrue: [ ^ self ].
	aDiagramElement bounds: (OPNodeBounds
			 withPosition: aDiagramElement bounds position + delta
			 extent: aDiagramElement bounds extent).
	aDiagramElement updateRenderFromSelf
]

{ #category : 'palette' }
OPDiagramBuilder >> readPaletteEntries [

	| palette |
	palette := diagramController editor ifNotNil: [ :editor | editor palette ].
	palette ifNil: [ OPDiagramBuildError signal: 'The diagram has no palette' ].
	^ palette entries
		  collect: [ :each | self paletteEntryOf: each ]
		  thenSelect: [ :each | each isNotNil ]
]

{ #category : 'commands' }
OPDiagramBuilder >> refresh: aController [
	"Show a change of the model (name, stereotype...) in the diagram and the properties form."

	aController viewModel ifNotNil: [ :viewModel | viewModel modelChanged ].
	aController diagramElement ifNotNil: [ :element |
		element isRendered ifTrue: [ aController modelChanged ] ]
]

{ #category : 'naming' }
OPDiagramBuilder >> rename: aController to: aName [
	"For elements being created; the creation itself is the undoable step."

	(aController model respondsTo: #name:) ifFalse: [
		OPDiagramBuildError signal: (self describe: aController) , ' has no name' ].
	aController model name: aName asString.
	self refresh: aController
]

{ #category : 'relations' }
OPDiagramBuilder >> setMultiplicity: aString ofEnd: anEnd in: anAssociationController [
	"E.g. '1', '0..1', '1..*', '*' (see OPMultiplicityParser) at an end of a UML association. Undoable."

	| bounds old new |
	bounds := [ OPMultiplicityParser boundsFrom: aString ]
		          on: OPInvalidMultiplicity
		          do: [ :error | OPDiagramBuildError signal: error messageText ].
	old := {
		       anEnd lowerValue.
		       anEnd upperValue }.
	new := {
		       (OPUMLLiteralInteger new
			        value: bounds first;
			        yourself).
		       (OPUMLLiteralUnlimitedNatural new
			        value: bounds second;
			        yourself) }.
	self execute: (OPBlockCommand
			 named: 'Change multiplicity'
			 execute: [
				 anEnd
					 lowerValue: new first;
					 upperValue: new second.
				 self refresh: anAssociationController ]
			 undo: [
				 anEnd
					 lowerValue: old first;
					 upperValue: old second.
				 self refresh: anAssociationController ])
]

{ #category : 'stereotypes' }
OPDiagramBuilder >> setStereotypeNamed: aNameOrNil of: aController [
	"E.g. OntoUML 'Kind', 'Role', 'Mediation'; nil removes the stereotype. Undoable."

	self
		applyStereotype: (aNameOrNil ifNotNil: [ self stereotypeNamed: aNameOrNil asString ])
		to: aController
]

{ #category : 'stereotypes' }
OPDiagramBuilder >> stereotypeNameOf: aModel [
	"Name of the first applied stereotype (e.g. 'Kind'), or nil."

	(aModel respondsTo: #appliedStereotypes) ifFalse: [ ^ nil ].
	aModel appliedStereotypes ifEmpty: [ ^ nil ].
	^ [ aModel appliedStereotypes first umlClassName asString ]
		  on: Error
		  do: [ aModel appliedStereotypes first class name asString ]
]

{ #category : 'stereotypes' }
OPDiagramBuilder >> stereotypeNamed: aString [

	^ self stereotypes
		  detect: [ :each | each name asLowercase = aString asLowercase ]
		  ifNone: [
			  OPDiagramBuildError signal: (self stereotypes
					   ifEmpty: [ 'The model has no profile with stereotypes' ]
					   ifNotEmpty: [ :all |
						   'Unknown stereotype "' , aString , '". Stereotypes: '
						   , (', ' join: (all collect: [ :each | each name ])) ]) ]
]

{ #category : 'stereotypes' }
OPDiagramBuilder >> stereotypes [
	"Non-abstract stereotypes of the profiles applied to the diagram's model."

	| root |
	root := diagramController model.
	(root respondsTo: #profileApplications) ifFalse: [ ^ #(  ) ].
	^ root profileApplications flatCollect: [ :each |
		  each appliedProfile ownedStereotype reject: [ :stereotype | stereotype isAbstract ] ]
]

{ #category : 'geometry' }
OPDiagramBuilder >> topLeftCorrectionOf: aDiagramElement to: aPoint [

	| rectangle |
	(aDiagramElement bounds isNil or: [ aDiagramElement isRendered not ]) ifTrue: [ ^ 0 @ 0 ].
	rectangle := self displayedRectangleOf: aDiagramElement.
	rectangle ifNil: [ ^ 0 @ 0 ].
	^ aPoint - rectangle topLeft floor
]

{ #category : 'naming' }
OPDiagramBuilder >> typeNameOf: aController [

	^ [ aController viewModel nameOfType asString ]
		  on: Error
		  do: [ aController model class name asString ]
]
