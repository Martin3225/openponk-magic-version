"
Window for adding OntoUML elements to a diagram by writing them as text (see OPOntoUMLTextImport).

Left: the text, and under it what will be added or what is wrong (line by line, with suggestions for typos), updated while typing. Right: a cheat sheet of the notation. Patterns (phases, a role with its relator...) can be inserted as text and renamed. Cmd+Enter or Ctrl+Enter adds; the window stays open for more.
"
Class {
	#name : 'OPOntoUMLTextDialog',
	#superclass : 'SpPresenter',
	#instVars : [
		'diagramController',
		'textInput',
		'previewLabel',
		'previewList',
		'helpText',
		'templatesButton',
		'closeButton',
		'addButton',
		'import'
	],
	#category : 'OpenPonk-Extras-OntoUML-Text',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Text'
}

{ #category : 'opening' }
OPOntoUMLTextDialog class >> openOn: aDiagramController [

	^ (self on: aDiagramController) open
]

{ #category : 'actions' }
OPOntoUMLTextDialog >> add [

	| created |
	(import isNil or: [ import hasErrors or: [ import isEmpty ] ]) ifTrue: [ ^ self ].
	created := [ import apply ]
		           on: Error
		           do: [ :error |
			           previewList items: { (#error -> error messageText asString) }.
			           ^ self ].
	textInput text: ''.
	self updatePreview.
	^ created
]

{ #category : 'layout' }
OPOntoUMLTextDialog >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 6;
		  add: (SpPanedLayout newLeftToRight
				   positionOfSlider: 0.56;
				   add: (SpBoxLayout newTopToBottom
						    spacing: 4;
						    add: textInput;
						    add: previewLabel expand: false;
						    add: previewList height: 150;
						    yourself);
				   add: helpText;
				   yourself);
		  add: (SpBoxLayout newLeftToRight
				   spacing: 6;
				   add: templatesButton expand: false;
				   add: SpBoxLayout newLeftToRight;
				   add: closeButton width: 110;
				   add: addButton width: 200;
				   yourself)
		  height: 28;
		  yourself
]

{ #category : 'accessing' }
OPOntoUMLTextDialog >> import [
	"The analysis of the current text."

	^ import
]

{ #category : 'initialization' }
OPOntoUMLTextDialog >> initializePresenters [

	textInput := self newText
		             placeholder: (OPOntoUMLTexts at: #'template.phases.text');
		             whenTextChangedDo: [ self updatePreview ];
		             yourself.
	{
		Character cr meta.
		Character cr ctrl } do: [ :each | textInput bindKeyCombination: each toAction: [ self add ] ].
	previewLabel := self newLabel
		                label: (OPOntoUMLTexts at: #'dialog.preview');
		                displayBold: [ :label | true ];
		                yourself.
	previewList := self newList
		               display: [ :item | item value ];
		               displayIcon: [ :item | self iconOfPreviewItem: item ];
		               yourself.
	helpText := self newText
		            text: (OPOntoUMLTexts at: #'dialog.help');
		            beNotEditable;
		            yourself.
	templatesButton := self newButton
		                   label: (OPOntoUMLTexts at: #'dialog.templates');
		                   icon: (self iconNamed: #add);
		                   action: [ self popUpTemplates ];
		                   yourself.
	closeButton := self newButton
		               label: (OPOntoUMLTexts at: #'dialog.close');
		               action: [ self withWindowDo: [ :window | window close ] ];
		               yourself.
	addButton := self newButton
		             label: (OPOntoUMLTexts at: #'dialog.add');
		             icon: (self iconNamed: #smallOk);
		             action: [ self add ];
		             yourself.
	self updatePreview
]

{ #category : 'initialization' }
OPOntoUMLTextDialog >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: (OPOntoUMLTexts at: #'dialog.title');
		initialExtent: 980 @ 560
]

{ #category : 'actions' }
OPOntoUMLTextDialog >> insertTemplate: aKey [

	| current |
	current := textInput text asString trimRight.
	textInput text: (current isEmpty
			 ifTrue: [ OPOntoUMLTexts at: (aKey , '.text') asSymbol ]
			 ifFalse: [ current , String cr , String cr , (OPOntoUMLTexts at: (aKey , '.text') asSymbol) ]).
	self updatePreview
]

{ #category : 'private' }
OPOntoUMLTextDialog >> iconOfPreviewItem: anAssociation [

	^ self iconNamed: (anAssociation key = #error
			   ifTrue: [ #smallError ]
			   ifFalse: [
				   anAssociation key = #plan
					   ifTrue: [ #smallOk ]
					   ifFalse: [ #smallInfo ] ])
]

{ #category : 'actions' }
OPOntoUMLTextDialog >> popUpTemplates [

	| menu |
	menu := MenuMorph new.
	self templateKeys do: [ :each |
		menu
			add: (OPOntoUMLTexts at: each asSymbol)
			target: self
			selector: #insertTemplate:
			argument: each ].
	menu popUpInWorld
]

{ #category : 'initialization' }
OPOntoUMLTextDialog >> setModelBeforeInitialization: aDiagramController [

	diagramController := aDiagramController
]

{ #category : 'accessing' }
OPOntoUMLTextDialog >> templateKeys [

	^ OPOntoUMLTexts patterns collect: [ :each | 'template.' , each ]
]

{ #category : 'accessing' }
OPOntoUMLTextDialog >> text: aString [

	textInput text: aString.
	self updatePreview
]

{ #category : 'updating' }
OPOntoUMLTextDialog >> updatePreview [

	| text items |
	text := textInput text asString.
	import := [ OPOntoUMLTextImport on: diagramController text: text ]
		          on: Error
		          do: [ nil ].
	items := OrderedCollection new.
	import ifNil: [ ^ addButton disable ].
	import hasErrors
		ifTrue: [
			items add: #info -> (OPOntoUMLTexts at: #'plan.errors').
			import errorLines do: [ :each | items add: #error -> each ] ]
		ifFalse: [
			import isEmpty
				ifTrue: [ items add: #info -> (OPOntoUMLTexts at: #'plan.nothing') ]
				ifFalse: [ import planLines do: [ :each | items add: #plan -> each ] ] ].
	previewList items: items.
	addButton enabled: (import hasErrors not and: [ import isEmpty not ])
]
