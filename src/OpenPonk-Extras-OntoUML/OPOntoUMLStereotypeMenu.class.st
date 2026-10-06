"
Menu for changing the OntoUML stereotype of the selected classes (or, when no class is selected, relations), grouped as students learn them, with the stereotype's color and a one-line explanation with examples. One undoable step for the whole selection.
"
Class {
	#name : 'OPOntoUMLStereotypeMenu',
	#superclass : 'OPOntoUMLPopupMenu',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'applying' }
OPOntoUMLStereotypeMenu >> applyStereotypeNamed: aNameOrNil [

	| builder |
	builder := OPDiagramBuilder on: diagramController.
	builder inTransactionLabeled: (OPOntoUMLTexts at: #'stereotypeMenu.undo') do: [
		self targets do: [ :each | builder setStereotypeNamed: aNameOrNil of: each ] ].
	diagramController canvas ifNotNil: [ :canvas | canvas signalUpdate ]
]

{ #category : 'accessing' }
OPOntoUMLStereotypeMenu >> availableStereotypeNames [

	^ ((OPDiagramBuilder on: diagramController) stereotypes collect: [ :each | each name ]) asSet
]

{ #category : 'building' }
OPOntoUMLStereotypeMenu >> buildMenu [

	| targets menu available current first |
	targets := self targets.
	targets ifEmpty: [ ^ nil ].
	available := self availableStereotypeNames.
	current := self currentStereotypeName.
	menu := MenuMorph new.
	menu addTitle: (targets size = 1
			 ifTrue: [ OPOntoUMLTexts at: #'stereotypeMenu.titleOne' with: { (OPOntoUMLStereotypeCatalog displayNameOf: targets first model) } ]
			 ifFalse: [ OPOntoUMLTexts at: #'stereotypeMenu.titleMany' with: { targets size printString } ]).
	first := true.
	self groups do: [ :group |
		| names |
		names := group value select: [ :each | available includes: each ].
		names ifNotEmpty: [
			first ifFalse: [ menu addLine ].
			first := false.
			self groups size > 1 ifTrue: [
				self addGroupLabel: (OPOntoUMLStereotypeCatalog groupLabelOf: group key) to: menu ].
			names do: [ :each |
				self
					addItem: each
					note: (self noteFor: each current: each = current)
					shortcut: (self isForRelations ifFalse: [ OPOntoUMLStereotypeCatalog shortcutLabelOf: each ])
					icon: (OPOntoUMLStereotypeCatalog swatchOf: each)
					to: menu
					selector: #applyStereotypeNamed:
					arguments: { each } ] ] ].
	menu addLine.
	self
		addItem: (OPOntoUMLTexts at: #'stereotype.none')
		note: (current isNil ifTrue: [ OPOntoUMLTexts at: #'menu.current' ])
		icon: (OPOntoUMLStereotypeCatalog swatchOf: nil)
		to: menu
		selector: #applyStereotypeNamed:
		arguments: #( nil ).
	^ menu
]

{ #category : 'accessing' }
OPOntoUMLStereotypeMenu >> currentStereotypeName [
	"The stereotype all targets have, or nil."

	| names |
	names := (self targets collect: [ :each |
		          OPOntoUMLStereotypeCatalog stereotypeNameOf: each model ]) asSet.
	^ names size = 1
		  ifTrue: [ names anyOne ]
		  ifFalse: [ nil ]
]

{ #category : 'accessing' }
OPOntoUMLStereotypeMenu >> groups [

	^ self isForRelations
		  ifTrue: [ OPOntoUMLStereotypeCatalog relationGroups ]
		  ifFalse: [ OPOntoUMLStereotypeCatalog classGroups ]
]

{ #category : 'testing' }
OPOntoUMLStereotypeMenu >> isForRelations [

	^ self targets notEmpty and: [ self targets first model isKindOf: OPUMLAssociation ]
]

{ #category : 'building' }
OPOntoUMLStereotypeMenu >> noteFor: aStereotypeName current: isCurrent [

	| note |
	note := OPOntoUMLStereotypeCatalog descriptionOf: aStereotypeName.
	^ isCurrent
		  ifTrue: [ note , '  ' , (OPOntoUMLTexts at: #'menu.current') ]
		  ifFalse: [ note ]
]

{ #category : 'accessing' }
OPOntoUMLStereotypeMenu >> targets [
	"Selected classes; when none, selected relations."

	| classes |
	classes := controllers select: [ :each | each model class == OPUMLClass ].
	classes ifNotEmpty: [ ^ classes ].
	^ controllers select: [ :each | each model isKindOf: OPUMLAssociation ]
]
