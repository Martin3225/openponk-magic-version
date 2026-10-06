"
The stereotype and generalization set menus, their commands and shortcuts.
"
Class {
	#name : 'OPOntoUMLMenusTest',
	#superclass : 'OPOntoUMLAssistantTestCase',
	#category : 'OpenPonk-Extras-OntoUML-Tests',
	#package : 'OpenPonk-Extras-OntoUML-Tests'
}

{ #category : 'tests - generalization sets' }
OPOntoUMLMenusTest >> testGeneralizationSetFromSelectedSubclasses [

	| person child adult elder sets generalizations set |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	child := self class: 'Phase' named: 'Child'.
	adult := self class: 'Phase' named: 'Adult'.
	elder := self class: 'Phase' named: 'Elder'.
	{ child. adult. elder } do: [ :each | self generalize: each to: person ].
	sets := OPOntoUMLGeneralizationSets on: diagramController.

	generalizations := sets generalizationsForSelection: { child model. adult model }.
	self assert: (generalizations collect: [ :each | each specific ]) asArray equals: { child model. adult model }.
	set := sets setGeneralizations: generalizations disjoint: false covering: false.
	self deny: set isDisjoint.

	"The same set is changed and extended, never a second one added."
	generalizations := sets generalizationsForSelection: { person model }.
	self assert: generalizations size equals: 3.
	self assert: (sets setGeneralizations: generalizations disjoint: true covering: true) identicalTo: set.
	self assert: set generalizations size equals: 3.
	self assert: set isDisjoint & set isCovering.
	self assert: (diagramController model packagedElements select: [ :each | each isKindOf: OPUMLGeneralizationSet ]) size equals: 1.

	"A parent with some of its children."
	self
		assert: (sets generalizationsForSelection: { person model. elder model }) size
		equals: 1.
	"Classes without a common parent say nothing."
	self assert: (sets generalizationsForSelection: { person model. child model. (self class: 'Kind' named: 'Dog') model }) isEmpty.

	sets removeFromSet: (sets generalizationsForSelection: { person model }).
	self assert: (diagramController model packagedElements select: [ :each | each isKindOf: OPUMLGeneralizationSet ]) isEmpty.
	diagramController undoManager undo.
	self assert: set generalizations size equals: 3
]

{ #category : 'tests - generalization sets' }
OPOntoUMLMenusTest >> testGeneralizationSetMenuExplainsKindsAndRecommendsForPhases [

	| person child adult menu labels |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	child := self class: 'Phase' named: 'Child'.
	adult := self class: 'Phase' named: 'Adult'.
	self generalize: child to: person.
	self generalize: adult to: person.
	menu := OPOntoUMLGeneralizationSetMenu new
		        diagramController: diagramController;
		        controllers: { child. adult };
		        buildMenu.
	labels := (menu items select: [ :each | each isKindOf: OPOntoUMLMenuItemMorph ]) collect: [ :each |
		          each contents , ' ' , each note ].

	self assert: labels size equals: 4.
	self assert: labels first equals:
		'{disjoint, complete} každá instance «Person» patří právě do jedné z nich  (doporučeno pro fáze)'.

	((menu items detect: [ :each | each contents = '{disjoint, complete}' ])) doButtonAction.
	self assert: child model generalizations first generalizationSets first isDisjoint.
	self assert: child model generalizations first generalizationSets first isCovering
]

{ #category : 'tests - generalization sets' }
OPOntoUMLMenusTest >> testGeneralizationSetShortcut [

	| person child adult |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	child := self class: 'Phase' named: 'Child'.
	adult := self class: 'Phase' named: 'Adult'.
	self generalize: child to: person.
	self generalize: adult to: person.
	self select: { child. adult }.

	self pressKey: $g withModifier: 64.

	self assert: self menusInWorld size equals: 1.
	self assert: (self menusInWorld first items anySatisfy: [ :each | each contents = '{disjoint, complete}' ])
]

{ #category : 'tests - stereotypes' }
OPOntoUMLMenusTest >> testStereotypeMenuChangesTheSelectionInOneStep [

	| a b menu |
	self openOntoUML.
	a := self class: 'Kind' named: 'Student'.
	b := self class: 'Kind' named: 'Teacher'.
	menu := OPOntoUMLStereotypeMenu new
		        diagramController: diagramController;
		        controllers: { a. b };
		        yourself.

	menu applyStereotypeNamed: 'Role'.

	self assert: (self stereotypeOf: a) equals: 'Role'.
	self assert: (self stereotypeOf: b) equals: 'Role'.
	diagramController undoManager undo.
	self assert: (self stereotypeOf: a) equals: 'Kind'.
	self assert: (self stereotypeOf: b) equals: 'Kind'.
	diagramController undoManager redo.
	menu applyStereotypeNamed: nil.
	self assert: (self stereotypeOf: a) isNil
]

{ #category : 'tests - stereotypes' }
OPOntoUMLMenusTest >> testStereotypeMenuOffersGroupsDescriptionsAndCurrent [

	| person items kind |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	items := (OPOntoUMLStereotypeMenu new
		          diagramController: diagramController;
		          controllers: { person };
		          buildMenu) items select: [ :each | each isKindOf: OPOntoUMLMenuItemMorph ].

	self
		assert: (items collect: [ :each | each contents ]) asArray
		equals: #( 'Kind' 'SubKind' 'Role' 'Phase' 'Collective' 'Quantity' 'Category' 'RoleMixin'
			   'PhaseMixin' 'Mixin' 'Relator' 'Mode' 'Quality' 'bez stereotypu' ).
	kind := items first.
	self assert: kind note equals: 'rigidní, dává identitu (Osoba, Auto)  (aktuální)'.
	self assert: kind icon notNil
]

{ #category : 'tests - stereotypes' }
OPOntoUMLMenusTest >> testStereotypeMenuForRelations [

	| car garage association menu |
	self openOntoUML.
	car := self class: 'Kind' named: 'Car'.
	garage := self class: 'Kind' named: 'Garage'.
	association := self connect: car to: garage by: 'Association'.
	menu := OPOntoUMLStereotypeMenu new
		        diagramController: diagramController;
		        controllers: { association };
		        yourself.
	self assert: menu isForRelations.
	self assert: ((menu buildMenu items collect: [ :each | each contents ]) includes: 'ComponentOf').

	menu applyStereotypeNamed: 'ComponentOf'.

	self assert: (self stereotypeOf: association) equals: 'ComponentOf'
]

{ #category : 'tests - stereotypes' }
OPOntoUMLMenusTest >> testStereotypeShortcutAndContextMenu [

	| person |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	self assert: (OPOntoUMLChangeStereotypeCommand canBeExecutedInContext: (self contextFor: { person })).
	self assert: (OPOntoUMLGeneralizationSetCommand canBeExecutedInContext: (self contextFor: { person })).
	self select: { person }.

	self pressKey: $t withModifier: 16.

	self assert: self menusInWorld size equals: 1.
	(self menusInWorld first items detect: [ :each | each contents = 'SubKind' ]) doButtonAction.
	self assert: (self stereotypeOf: person) equals: 'SubKind'
]

{ #category : 'tests - stereotypes' }
OPOntoUMLMenusTest >> testEveryShortcutHasItsCommandAndNoKeyIsUsedTwice [

	| keys |
	keys := OPOntoUMLStereotypeCatalog shortcuts collect: [ :each | each second -> each third ].
	keys := keys , (OPOntoUMLStereotypeCatalog toolShortcuts collect: [ :each | each second -> each third ]).
	self assert: keys asSet size equals: keys size.
	self deny: (keys anySatisfy: [ :each | each key = $m or: [ each key = $t ] ]).
	OPOntoUMLStereotypeCatalog shortcuts do: [ :each |
		self assert: (OPOntoUMLStereotypeKeyCommand allSubclasses anySatisfy: [ :command |
				 command stereotypeName = each first ]) ].
	self
		assert: OPOntoUMLStereotypeKeyCommand allSubclasses size
		equals: OPOntoUMLStereotypeCatalog shortcuts size
]

{ #category : 'tests - stereotypes' }
OPOntoUMLMenusTest >> testSingleKeysSetTheStereotypeOfSelectedClasses [

	| a b car garage association |
	self openOntoUML.
	a := self class: 'Class' named: 'Student'.
	b := self class: 'Class' named: 'Teacher'.
	self select: { a. b }.

	self pressKey: $k withModifier: 0.
	self assert: (self stereotypeOf: a) equals: 'Kind'.
	self assert: (self stereotypeOf: b) equals: 'Kind'.
	self pressKey: $r withModifier: 8.
	self assert: (self stereotypeOf: a) equals: 'RoleMixin'.
	self pressKey: $e withModifier: 0.
	self assert: (self stereotypeOf: b) equals: 'Relator'.
	diagramController undoManager undo.
	self assert: (self stereotypeOf: a) equals: 'RoleMixin'.
	self assert: (self stereotypeOf: b) equals: 'RoleMixin'.

	"A selected relation gets its stereotype from the menu (T); a stereotype key chooses the palette tool instead."
	car := self class: 'Kind' named: 'Car'.
	garage := self class: 'Kind' named: 'Garage'.
	association := self connect: car to: garage by: 'Association'.
	self select: { association }.
	self pressKey: $k withModifier: 0.
	self assert: (self stereotypeOf: association) isNil.
	self assert: self selectedPaletteLabel equals: 'Kind'.
	workbench focusedEditor palette selectSelectionTool.
	self select: { association }.
	self pressKey: $t withModifier: 0.
	self assert: self menusInWorld size equals: 1.
	self assert: (self menusInWorld first items anySatisfy: [ :each | each contents = 'Mediation' ])
]

{ #category : 'tests - stereotypes' }
OPOntoUMLMenusTest >> testStereotypeMenuShowsTheKeys [

	| person items |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	items := (OPOntoUMLStereotypeMenu new
		          diagramController: diagramController;
		          controllers: { person };
		          buildMenu) items select: [ :each | each isKindOf: OPOntoUMLMenuItemMorph ].

	self assert: (items detect: [ :each | each contents = 'Kind' ]) shortcut equals: 'K'.
	self assert: (items detect: [ :each | each contents = 'Relator' ]) shortcut equals: 'E'.
	self assert: (items detect: [ :each | each contents = 'RoleMixin' ]) shortcut equals: 'Shift+R'.
	self assert: (items detect: [ :each | each contents = 'bez stereotypu' ]) shortcut isNil
]

{ #category : 'tests - stereotypes' }
OPOntoUMLMenusTest >> testKeysChooseTheToolWhenNoClassIsSelected [
	"Keys instead of hunting in the palette: K chooses the Kind tool, L Class, G Generalization, A Association; a click on the canvas then creates the element."

	| palette person created |
	self openOntoUML.
	palette := workbench focusedEditor palette.
	person := self class: 'Kind' named: 'Person'.
	diagramController deselectAll.

	#( #( $k 0 'Kind' ) #( $r 8 'RoleMixin' ) #( $l 0 'Class' ) #( $g 0 'Generalization' ) #( $a 0 'Association' ) )
		do: [ :each |
			self pressKey: each first withModifier: each second.
			self assert: self selectedPaletteLabel equals: each third ].

	self pressKey: $e withModifier: 0.
	palette selectedTool selectedControllers: { diagramController } onPosition: 300 @ 300.
	created := diagramController model packagedElements detect: [ :each |
		           each class == OPUMLClass and: [ each ~~ person model ] ].
	self assert: (OPOntoUMLStereotypeCatalog stereotypeNameOf: created) equals: 'Relator'.
	self assert: self selectedPaletteLabel equals: 'Select'.
	self assert: ((palette entries detect: [ :each | each label = 'Kind' ]) help includesSubstring: 'Klávesa K')
		description: 'palette tooltips show the keys once the panel has checked'
]

{ #category : 'helpers' }
OPOntoUMLMenusTest >> selectedPaletteLabel [

	^ (workbench focusedEditor palette instVarNamed: #selectedItem) label
]
