"
Live OntoUML check in the editor, under the canvas of OntoUML diagrams.

- A status line tells at a glance whether the model breaks OntoUML rules (""7 errors"") and is updated shortly after every change (every undoable step of OpenPonk), so students see the effect of what they just did.
- Problem elements get badges on the canvas (OPOntoUMLProblemMarkers).
- The list (shown on demand, or by clicking a badge) explains the selected problem: what is wrong, how to fix it, a quick fix where one is possible, the element in the diagram and a link to the OntoUML documentation.
- Warnings (anti-patterns and recommendations) are hidden unless asked for: they are hints that may well be fine, and showing them all the time buries the errors.

The check (OPOntoUMLChecker) takes milliseconds, so it runs in the UI process; it never opens a debugger.

The panel is put into the editor's layout by OPEditorLayout>>#applyOn: (see #addTo:of:), only for editors of the OntoUML plugin.
"
Class {
	#name : 'OPOntoUMLProblemsPanel',
	#superclass : 'SpPresenter',
	#instVars : [
		'editor',
		'problems',
		'expanded',
		'subscribedUndoManager',
		'statusIcon',
		'statusLabel',
		'warningsCheckBox',
		'toggleButton',
		'table',
		'explanationText',
		'fixButton',
		'showButton',
		'docsButton',
		'updatingList',
		'hasChecked',
		'waitingForDiagram',
		'applicable'
	],
	#classVars : [
		'ShowList',
		'ShowWarnings'
	],
	#category : 'OpenPonk-Extras-OntoUML-Problems',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Problems'
}

{ #category : 'editor layout' }
OPOntoUMLProblemsPanel class >> addTo: aLayout of: anEditor [
	"Put the panel of an OntoUML editor between its canvas and zoom toolbar; other editors are left as they are."

	| section panel |
	(self isFor: anEditor) ifFalse: [ ^ aLayout ].
	section := (self canvasSectionIn: aLayout) ifNil: [ ^ aLayout ].
	panel := self panelOf: anEditor.
	panel isApplicable ifFalse: [ ^ aLayout ].
	(section children includes: #zoomToolbar) ifTrue: [ section remove: #zoomToolbar ].
	section add: panel withConstraints: [ :constraints |
		constraints
			expand: false;
			height: panel preferredHeight ].
	section add: #zoomToolbar expand: false.
	^ aLayout
]

{ #category : 'editor layout' }
OPOntoUMLProblemsPanel class >> canvasSectionIn: aLayout [

	((aLayout isKindOf: SpBoxLayout) and: [ aLayout children includes: #canvasPresenter ]) ifTrue: [
		^ aLayout ].
	(aLayout isKindOf: SpExecutableLayout) ifFalse: [ ^ nil ].
	aLayout children do: [ :each |
		(self canvasSectionIn: each) ifNotNil: [ :found | ^ found ] ].
	^ nil
]

{ #category : 'testing' }
OPOntoUMLProblemsPanel class >> isFor: anEditor [

	^ anEditor plugin isKindOf: OntoUMLPlugin
]

{ #category : 'editor layout' }
OPOntoUMLProblemsPanel class >> panelOf: anEditor [

	^ anEditor additionalSubpresentersMap
		  at: #ontoUMLProblemsPanel
		  ifAbsentPut: [ anEditor instantiate: self on: anEditor ]
]

{ #category : 'preferences' }
OPOntoUMLProblemsPanel class >> showList [

	^ ShowList ifNil: [ false ]
]

{ #category : 'preferences' }
OPOntoUMLProblemsPanel class >> showList: aBoolean [

	ShowList := aBoolean
]

{ #category : 'preferences' }
OPOntoUMLProblemsPanel class >> showWarnings [

	^ ShowWarnings ifNil: [ false ]
]

{ #category : 'preferences' }
OPOntoUMLProblemsPanel class >> showWarnings: aBoolean [

	ShowWarnings := aBoolean
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> applyFix [

	| problem |
	problem := self selectedProblem ifNil: [ ^ self ].
	problem fix ifNil: [ ^ self ].
	problem fix applyIn: self diagramController.
	self check
]

{ #category : 'layout' }
OPOntoUMLProblemsPanel >> bodyLayout [
	"Narrow enough for a laptop screen: the title is in the explanation, secondary actions are icons."

	^ SpPanedLayout newLeftToRight
		  positionOfSlider: 0.5;
		  add: table;
		  add: (SpBoxLayout newTopToBottom
				   spacing: 4;
				   add: explanationText;
				   add: (SpBoxLayout newLeftToRight
						    spacing: 4;
						    add: fixButton;
						    add: showButton width: 30;
						    add: docsButton width: 30;
						    yourself)
				   height: 26;
				   yourself);
		  yourself
]

{ #category : 'checking' }
OPOntoUMLProblemsPanel >> check [
	"Check the model now and show the result."

	| diagramController |
	diagramController := self diagramController.
	(diagramController isNil or: [ diagramController model isNil ]) ifTrue: [
		"The editor gets its diagram after its layout is built; wait for it (a while)."
		(waitingForDiagram := waitingForDiagram + 1) < 50 ifTrue: [ self scheduleCheck ].
		^ self ].
	waitingForDiagram := 0.
	self ensureSubscribed.
	self showKeysInPalette.
	"The OntoUML plugin also gets plain UML class diagrams (a UML package without profiles); they have no panel."
	(OPOntoUMLStereotypeCatalog isOntoUMLDiagram: diagramController) = applicable ifFalse: [
		applicable := applicable not.
		self relayoutEditor ].
	applicable ifFalse: [
		problems := #(  ).
		^ self markers show: problems ].
	problems := [
	            OPOntoUMLChecker
		            problemsIn: diagramController model
		            includeWarnings: self class showWarnings ]
		            on: Error
		            do: [ #(  ) ].
	hasChecked := true.
	self updateStatus.
	self updateList.
	self markers show: problems
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> diagramController [

	^ editor ifNotNil: [ editor diagramController ]
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> ensureSubscribed [

	| undoManager |
	undoManager := self diagramController undoManager.
	undoManager == subscribedUndoManager ifTrue: [ ^ self ].
	subscribedUndoManager ifNotNil: [ :old | old announcer unsubscribe: self ].
	subscribedUndoManager := undoManager.
	undoManager ifNotNil: [
		undoManager announcer weak when: OPUndoRedoChanged send: #scheduleCheck to: self ]
]

{ #category : 'layout' }
OPOntoUMLProblemsPanel >> headerLayout [

	^ SpBoxLayout newLeftToRight
		  spacing: 6;
		  vAlignCenter;
		  add: statusIcon width: 20;
		  add: statusLabel;
		  add: warningsCheckBox expand: false;
		  add: toggleButton withConstraints: [ :constraints |
			  constraints
				  expand: false;
				  width: (self widthOfText: toggleButton label) + 30 ];
		  yourself
]

{ #category : 'layout' }
OPOntoUMLProblemsPanel >> defaultLayout [

	expanded ifFalse: [ ^ self headerLayout ].
	^ SpBoxLayout newTopToBottom
		  spacing: 4;
		  add: self headerLayout height: 26;
		  add: self bodyLayout;
		  yourself
]

{ #category : 'initialization' }
OPOntoUMLProblemsPanel >> initialize [

	problems := #(  ).
	expanded := self class showList.
	updatingList := false.
	hasChecked := false.
	waitingForDiagram := 0.
	applicable := true.
	super initialize.
	OPOntoUMLTexts announcer weak when: OPOntoUMLLanguageChanged send: #languageChanged to: self
]

{ #category : 'initialization' }
OPOntoUMLProblemsPanel >> initializePresenters [

	statusIcon := self newImage.
	statusLabel := self newLabel
		               displayBold: [ :label | self errorCount > 0 ];
		               displayColor: [ :label |
			               self errorCount > 0
				               ifTrue: [ Color fromHexString: 'B3261E' ]
				               ifFalse: [ self theme textColor ] ];
		               yourself.
	warningsCheckBox := self newCheckBox
		                    state: self class showWarnings;
		                    whenChangedDo: [ :state |
			                    state = self class showWarnings ifFalse: [ self showWarnings: state ] ];
		                    yourself.
	toggleButton := self newButton
		                action: [ self toggleList ];
		                yourself.
	table := self newTable
		         addColumn: ((SpImageTableColumn evaluated: [ :problem | self iconOf: problem ])
				          width: 24;
				          yourself);
		         addColumn: (SpStringTableColumn title: '' evaluated: [ :problem | problem title ]);
		         hideColumnHeaders;
		         whenSelectionChangedDo: [ :selection | self selectionChanged ];
		         yourself.
	explanationText := self newText
		                   beNotEditable;
		                   beWrapWord;
		                   yourself.
	fixButton := self newButton
		             icon: (self iconNamed: #smallDoIt);
		             action: [ self applyFix ];
		             yourself.
	showButton := self newButton
		              icon: (self iconNamed: #glamorousBrowse);
		              action: [ self selectedProblem ifNotNil: [ :problem | self reveal: problem ] ];
		              yourself.
	docsButton := self newButton
		              icon: (self iconNamed: #smallHelp);
		              action: [ self openDocumentation ];
		              yourself.
	self updateTexts.
	self whenBuiltDo: [ self scheduleCheckIn: 50 ]
]

{ #category : 'private' }
OPOntoUMLProblemsPanel >> widthOfText: aString [

	^ (StandardFonts defaultFont widthOfString: aString asString) ceiling
]

{ #category : 'accessing' }
OPOntoUMLProblemsPanel >> errorCount [

	^ problems count: [ :each | each isError ]
]

{ #category : 'private' }
OPOntoUMLProblemsPanel >> iconOf: aProblem [

	^ self iconNamed: (aProblem isError
			   ifTrue: [ #smallError ]
			   ifFalse: [ #smallWarning ])
]

{ #category : 'testing' }
OPOntoUMLProblemsPanel >> isExpanded [

	^ expanded
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> languageChanged [
	"Also received by panels of editors closed but not yet garbage collected; never fail for them."

	[
	self updateTexts.
	self relayoutEditor.
	hasChecked ifTrue: [ self check ] ]
		on: Error
		do: [ "a closed editor" ]
]

{ #category : 'accessing' }
OPOntoUMLProblemsPanel >> markers [

	^ (OPOntoUMLProblemMarkers on: self diagramController)
		  onClick: [ :problem | self showProblem: problem ];
		  yourself
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> openDocumentation [

	self selectedProblem ifNotNil: [ :problem |
		problem documentationUrl ifNotNil: [ :url | WebBrowser openOn: url ] ]
]

{ #category : 'layout' }
OPOntoUMLProblemsPanel >> preferredHeight [

	^ expanded
		  ifTrue: [ 210 ]
		  ifFalse: [ 28 ]
]

{ #category : 'accessing' }
OPOntoUMLProblemsPanel >> problems [

	^ problems
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> relayoutEditor [

	self layout: self defaultLayout.
	(editor isNotNil and: [ editor isBuilt ]) ifTrue: [ editor class currentLayout applyOn: editor ]
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> reveal: aProblem [
	"Select the element of the problem and scroll the canvas to it when it is out of sight."

	| diagramController controller shape canvas |
	diagramController := self diagramController ifNil: [ ^ self ].
	controller := diagramController controllerForModel: aProblem element ifNone: [ ^ self ].
	diagramController selectController: controller.
	shape := controller roassalShape ifNil: [ ^ self ].
	canvas := diagramController canvas.
	(canvas visibleRectangle containsRect: shape encompassingRectangle) ifFalse: [
		canvas camera translateTo: shape encompassingRectangle center ].
	canvas signalUpdate
]

{ #category : 'checking' }
OPOntoUMLProblemsPanel >> scheduleCheck [
	"Check shortly after the last of a burst of changes (e.g. typing a name)."

	self scheduleCheckIn: 400
]

{ #category : 'checking' }
OPOntoUMLProblemsPanel >> scheduleCheckIn: milliseconds [

	| world |
	world := self currentWorld.
	world ifNil: [ ^ self ].
	world removeAlarm: #check for: self.
	world
		addAlarm: #check
		withArguments: #(  )
		for: self
		at: Time millisecondClockValue + milliseconds
]

{ #category : 'testing' }
OPOntoUMLProblemsPanel >> isApplicable [
	"False for a diagram without the OntoUML profile; unknown (true) until the diagram is checked."

	^ applicable
]

{ #category : 'accessing' }
OPOntoUMLProblemsPanel >> selectedProblem [

	^ table selectedItem
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> selectionChanged [

	self updateDetail.
	updatingList ifTrue: [ ^ self ].
	self selectedProblem ifNotNil: [ :problem | self reveal: problem ]
]

{ #category : 'initialization' }
OPOntoUMLProblemsPanel >> setModelBeforeInitialization: anEditor [

	editor := anEditor
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> showKeysInPalette [
	"Tooltips of the palette buttons name their keys (K for Kind...), see OPOntoUMLStereotypeCatalog."

	editor palette ifNil: [ ^ self ].
	editor palette entries do: [ :each |
		(OPOntoUMLStereotypeCatalog keyLabelOf: each label asString) ifNotNil: [ :key |
			| help |
			help := OPOntoUMLTexts
				        at: ((OPOntoUMLStereotypeCatalog shortcuts anySatisfy: [ :shortcut |
						          shortcut first = each label asString ])
						         ifTrue: [ #'palette.key' ]
						         ifFalse: [ #'palette.toolKey' ])
				        with: { key }.
			each help = help ifFalse: [ each help: help ] ] ]
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> showProblem: aProblem [
	"Show the list with the problem selected (e.g. its badge was clicked). A check may have run meanwhile and answered new problem objects, so find the same problem by its element and rule."

	expanded ifFalse: [ self toggleList ].
	problems
		detect: [ :each | each element == aProblem element and: [ each rule = aProblem rule ] ]
		ifFound: [ :same | table selectItem: same ]
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> showWarnings: aBoolean [

	self class showWarnings: aBoolean.
	warningsCheckBox state = aBoolean ifFalse: [ warningsCheckBox state: aBoolean ].
	self check
]

{ #category : 'accessing' }
OPOntoUMLProblemsPanel >> statusText [

	| errors warnings |
	hasChecked ifFalse: [ ^ OPOntoUMLTexts at: #'panel.checking' ].
	errors := problems count: [ :each | each isError ].
	warnings := problems size - errors.
	problems ifEmpty: [
		^ OPOntoUMLTexts at: (self class showWarnings
				   ifTrue: [ #'panel.noProblems' ]
				   ifFalse: [ #'panel.noErrors' ]) ].
	^ OPOntoUMLTexts at: #'panel.summary' with: { (', ' join: ({
				    (errors > 0 ifTrue: [ OPOntoUMLTexts count: errors of: 'error' ]).
				    (warnings > 0 ifTrue: [ OPOntoUMLTexts count: warnings of: 'warning' ]) }
				    reject: [ :each | each isNil ])) }
]

{ #category : 'actions' }
OPOntoUMLProblemsPanel >> toggleList [

	expanded := expanded not.
	self class showList: expanded.
	self updateTexts.
	self relayoutEditor
]

{ #category : 'updating' }
OPOntoUMLProblemsPanel >> updateDetail [

	| problem |
	problem := self selectedProblem.
	problem ifNil: [
		explanationText text: (problems
				 ifEmpty: [
					 (OPOntoUMLTexts at: #'panel.allGood') , (self class showWarnings
						  ifTrue: [ '' ]
						  ifFalse: [ OPOntoUMLTexts at: #'panel.allGoodWarnings' ]) ]
				 ifNotEmpty: [ OPOntoUMLTexts at: #'panel.selectProblem' ]).
		fixButton hide.
		showButton disable.
		docsButton disable.
		^ self ].
	explanationText text: problem severityLabel , ': ' , problem title , String cr , String cr , problem explanation.
	problem fix
		ifNil: [ fixButton hide ]
		ifNotNil: [ :fix |
			fixButton
				label: fix label;
				show ].
	showButton enabled: ((self diagramController ifNotNil: [ :diagramController |
			  diagramController controllerForModel: problem element ifNone: [ nil ] ]) isNotNil).
	docsButton enabled: problem documentationUrl isNotNil
]

{ #category : 'updating' }
OPOntoUMLProblemsPanel >> updateList [
	"Keep the selected problem selected (same element and rule) across checks, without moving the user's selection in the diagram."

	| previous |
	previous := self selectedProblem.
	updatingList := true.
	[
	table items: problems.
	previous ifNotNil: [
		problems
			detect: [ :each | each element == previous element and: [ each rule = previous rule ] ]
			ifFound: [ :same | table selectItem: same ] ].
	self updateDetail ] ensure: [ updatingList := false ]
]

{ #category : 'updating' }
OPOntoUMLProblemsPanel >> updateStatus [

	statusLabel label: self statusText.
	statusIcon image: (hasChecked ifTrue: [
			 self iconNamed: (self errorCount > 0
					  ifTrue: [ #smallError ]
					  ifFalse: [
						  problems isEmpty
							  ifTrue: [ #smallOk ]
							  ifFalse: [ #smallWarning ] ]) ])
]

{ #category : 'updating' }
OPOntoUMLProblemsPanel >> updateTexts [

	warningsCheckBox label: (OPOntoUMLTexts at: #'panel.showWarnings').
	toggleButton label: (OPOntoUMLTexts at: (expanded
				  ifTrue: [ #'panel.hideList' ]
				  ifFalse: [ #'panel.showList' ])).
	warningsCheckBox help: (OPOntoUMLTexts at: #'panel.showWarningsHelp').
	showButton help: (OPOntoUMLTexts at: #'panel.showInDiagram').
	docsButton help: (OPOntoUMLTexts at: #'panel.learnMore').
	self updateStatus.
	self updateDetail
]
