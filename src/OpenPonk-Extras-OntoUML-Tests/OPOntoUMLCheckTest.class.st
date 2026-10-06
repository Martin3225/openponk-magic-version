"
The OntoUML model check: explanations, merged and cascading problems, quick fixes, the problems panel in the editor and its badges.
"
Class {
	#name : 'OPOntoUMLCheckTest',
	#superclass : 'OPOntoUMLAssistantTestCase',
	#category : 'OpenPonk-Extras-OntoUML-Tests',
	#package : 'OpenPonk-Extras-OntoUML-Tests'
}

{ #category : 'tests - check' }
OPOntoUMLCheckTest >> testCascadingProblemsAreReportedAtTheirCause [
	"Sub-roles of a role without a relator are not listed separately; the cause names them."

	| person member reviewer borrower problems |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	member := self class: 'Role' named: 'Member'.
	reviewer := self class: 'Role' named: 'Reviewer'.
	borrower := self class: 'Role' named: 'Borrower'.
	self generalize: member to: person.
	self generalize: reviewer to: member.
	self generalize: borrower to: member.

	problems := self problems.

	self assert: problems size equals: 1.
	self assert: problems first element identicalTo: member model.
	self assert: problems first alsoFixed asSet equals: {
			reviewer model.
			borrower model } asSet.
	self assert: (problems first explanation includesSubstring: 'Tím se vyřeší i: Borrower, Reviewer.')
]

{ #category : 'tests - check' }
OPOntoUMLCheckTest >> testClassWithoutStereotypeIsAnErrorWithQuickFix [

	| plain problems |
	self openOntoUML.
	plain := self class: 'Class' named: 'Thing'.

	problems := self problems.

	self assert: (problems collect: [ :each | each rule ]) asArray equals: #( #noStereotype ).
	self assert: problems first isError.
	self assert: problems first title equals: 'Třída «Thing» nemá stereotyp'.
	self assert: problems first fix label equals: 'Vybrat stereotyp...'.
	problems first fix applyIn: diagramController.
	self assert: self menusInWorld size equals: 1.
	(self menusInWorld first items detect: [ :each | each contents = 'Kind' ]) doButtonAction.
	self assert: (self stereotypeOf: plain) equals: 'Kind'.
	self assert: self problems isEmpty
]

{ #category : 'tests - check' }
OPOntoUMLCheckTest >> testExplanationsInEnglish [

	| person student |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	student := self class: 'Role' named: 'Student'.
	self generalize: student to: person.
	OPOntoUMLTexts language: #en.

	self
		assert: self problems first title
		equals: 'Role «Student» is not defined by a relationship'
]

{ #category : 'tests - check' }
OPOntoUMLCheckTest >> testInvalidGeneralizationIsExplainedOnceWithAllowedSubtypes [

	| person student problems |
	self openOntoUML.
	student := self class: 'Role' named: 'Student'.
	person := self class: 'Kind' named: 'Person'.
	self generalize: person to: student.

	problems := self problems select: [ :each | each rule = #invalidGeneralization ].

	self assert: problems size equals: 1.
	self assert: problems first title equals: 'Kind «Person» nemůže být podtypem Role «Student»'.
	self assert: (problems first explanation includesSubstring: 'Pod Role smí být jen: Role').
	self deny: (problems first explanation includesSubstring: 'Kind,')
]

{ #category : 'tests - check' }
OPOntoUMLCheckTest >> testPhasesQuickFixCreatesDisjointCompleteSet [

	| person child adult problems set |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	child := self class: 'Phase' named: 'Child'.
	adult := self class: 'Phase' named: 'Adult'.
	self generalize: child to: person.
	self generalize: adult to: person.
	problems := self problems.
	self assert: (problems collect: [ :each | each rule ]) asSet asArray equals: #( #phaseNotInSet ).
	self assert: problems first fix label equals: 'Vytvořit množinu {disjoint, complete}'.

	problems first fix applyIn: diagramController.

	self assert: self problems isEmpty.
	set := child model generalizations first generalizationSets first.
	self assert: set isDisjoint.
	self assert: set isCovering.
	self assert: set generalizations asSet equals: {
			child model generalizations first.
			adult model generalizations first } asSet.
	diagramController undoManager undo.
	self assert: child model generalizations first generalizationSets isEmpty
]

{ #category : 'tests - check' }
OPOntoUMLCheckTest >> testPhasesQuickFixMakesExistingSetDisjointComplete [

	| person child adult problems set |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	child := self class: 'Phase' named: 'Child'.
	adult := self class: 'Phase' named: 'Adult'.
	set := (OPOntoUMLGeneralizationSets on: diagramController)
		       setGeneralizations: {
				       (self generalize: child to: person) model.
				       (self generalize: adult to: person) model }
		       disjoint: false
		       covering: true.
	problems := self problems.
	self assert: (problems collect: [ :each | each rule ]) asSet asArray equals: #( #phaseSetNotDC ).

	problems first fix applyIn: diagramController.

	self assert: set isDisjoint.
	self assert: set isCovering.
	self assert: self problems isEmpty
]

{ #category : 'tests - check' }
OPOntoUMLCheckTest >> testRelatorWithMediationsDefinesRoles [

	| person student university study |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	student := self class: 'Role' named: 'Student'.
	self generalize: student to: person.
	self assert: (self problems collect: [ :each | each rule ]) asArray equals: #( #roleWithoutRelator ).
	self
		assert: self problems first title
		equals: 'Role «Student» není definovaná vztahem'.

	university := self class: 'Kind' named: 'University'.
	study := self class: 'Relator' named: 'Study'.
	self connect: study to: student by: 'Mediation'.
	self connect: study to: university by: 'Mediation'.

	self assert: self problems isEmpty
]

{ #category : 'tests - check' }
OPOntoUMLCheckTest >> testWarningsOnlyWhenAskedFor [

	| a b |
	self openOntoUML.
	a := self class: 'Kind' named: 'Car'.
	b := self class: 'Kind' named: 'Garage'.
	self connect: a to: b by: 'Association'.

	self assert: self problems isEmpty.
	self
		assert: (self problemsWithWarnings collect: [ :each | each rule ]) asArray
		equals: #( #associationNoStereotype ).
	self assert: self problemsWithWarnings first isWarning.
	self
		assert: self problemsWithWarnings first title
		equals: 'Vztah «Car – Garage» nemá stereotyp'
]

{ #category : 'tests - panel' }
OPOntoUMLCheckTest >> testBadgesAreDrawnOverTheCanvasNotInIt [
	"Badges are no shapes of the diagram (so they are neither saved nor exported) and take the mouse only over themselves."

	| person student shapesBefore markers badge clicked |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	student := self class: 'Role' named: 'Student'.
	self generalize: student to: person.
	shapesBefore := diagramController canvas shapes size.

	self panel check.

	self assert: diagramController canvas shapes size equals: shapesBefore.
	markers := OPOntoUMLProblemMarkers on: diagramController.
	self assert: markers overlay owner identicalTo: diagramController canvas morph.
	self assert: markers badges size equals: 1.
	badge := markers badges first.
	self assert: badge problems first element identicalTo: student model.
	self assert: badge isError.
	self assert: (markers overlay containsPoint: badge center).
	self deny: (markers overlay containsPoint: badge center + (40 @ 40)).
	self assert: badge center
		equals: diagramController canvas morph position
			+ (diagramController canvas camera fromSpaceToPixel: student roassalShape encompassingRectangle topRight)
			+ (-3 @ 3).

	clicked := nil.
	markers onClick: [ :problem | clicked := problem ].
	markers clicked: badge.
	self assert: clicked identicalTo: badge problems first
]

{ #category : 'tests - panel' }
OPOntoUMLCheckTest >> testPanelChecksAfterEveryChange [

	| panel person student |
	self openOntoUML.
	panel := self panel.
	panel check.
	self assert: panel statusText equals: 'OntoUML: bez chyb'.
	self assert: (diagramController undoManager announcer hasSubscriber: panel).

	person := self class: 'Kind' named: 'Person'.
	student := self class: 'Role' named: 'Student'.
	self generalize: student to: person.
	panel check.

	self assert: panel statusText equals: 'OntoUML: 1 chyba'.
	self assert: (OPOntoUMLProblemMarkers on: diagramController) badges size equals: 1.
	panel showWarnings: true.
	self assert: panel statusText equals: 'OntoUML: 1 chyba'.
	panel showWarnings: false
]

{ #category : 'tests - panel' }
OPOntoUMLCheckTest >> testPanelOnlyInOntoUMLEditors [

	self openOntoUML.
	self assert: (workbench focusedEditor additionalSubpresentersMap includesKey: #ontoUMLProblemsPanel).
	workbench application closeAllWindows.
	self openModel: (OPErd new
			 name: 'erd';
			 yourself).
	self deny: (workbench focusedEditor additionalSubpresentersMap includesKey: #ontoUMLProblemsPanel)
]

{ #category : 'tests - panel' }
OPOntoUMLCheckTest >> testPanelSelectionShowsExplanationAndElement [

	| panel person student |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	student := self class: 'Role' named: 'Student'.
	self generalize: student to: person.
	panel := self panel.
	panel check.

	panel showProblem: panel problems first.

	self assert: panel isExpanded.
	self assert: diagramController selectedControllers asArray equals: { student }.
	panel toggleList
]

{ #category : 'helpers' }
OPOntoUMLCheckTest >> panel [

	^ workbench focusedEditor additionalSubpresentersMap at: #ontoUMLProblemsPanel
]

{ #category : 'helpers' }
OPOntoUMLCheckTest >> problems [

	^ OPOntoUMLChecker problemsIn: diagramController model
]

{ #category : 'helpers' }
OPOntoUMLCheckTest >> problemsWithWarnings [

	^ OPOntoUMLChecker problemsIn: diagramController model includeWarnings: true
]

{ #category : 'tests - panel' }
OPOntoUMLCheckTest >> testLanguageSwitchUpdatesAnOpenPanel [

	| panel person student |
	self openOntoUML.
	person := self class: 'Kind' named: 'Person'.
	student := self class: 'Role' named: 'Student'.
	self generalize: student to: person.
	panel := self panel.
	panel check.
	self assert: panel statusText equals: 'OntoUML: 1 chyba'.

	OPOntoUMLTexts languageName: 'English'.

	self assert: panel statusText equals: 'OntoUML: 1 error'.
	self assert: panel problems first title equals: 'Role «Student» is not defined by a relationship'
]

{ #category : 'tests - panel' }
OPOntoUMLCheckTest >> testLiveCheckRunsShortlyAfterEveryChange [
	"No manual check: an undoable change schedules one (through the undo manager and a World alarm)."

	| panel person student |
	self openOntoUML.
	panel := self panel.
	panel check.
	person := self class: 'Kind' named: 'Person'.
	student := self class: 'Role' named: 'Student'.
	self generalize: student to: person.
	self assert: panel statusText equals: 'OntoUML: bez chyb'.

	self waitForLiveCheck.
	self assert: panel statusText equals: 'OntoUML: 1 chyba'.
	self assert: (OPOntoUMLProblemMarkers on: diagramController) badges size equals: 1.

	"Typing a name in the properties form is a (coalesced) property change."
	diagramController undoManager execute: (OPPropertyChangeCommand
			 viewModel: student viewModel
			 selector: #name
			 oldValue: 'Student'
			 newValue: 'Žák').
	self waitForLiveCheck.
	self assert: panel problems first title equals: 'Role «Žák» není definovaná vztahem'
]

{ #category : 'tests - panel' }
OPOntoUMLCheckTest >> testPanelHidesForPlainUmlDiagrams [
	"OpenPonk opens a UML package without profiles with the OntoUML plugin too; such a diagram gets no OntoUML panel."

	| editor panel |
	self openModel: (OPUMLPackage new
			 name: 'UML';
			 yourself).
	editor := workbench focusedEditor.
	panel := editor additionalSubpresentersMap at: #ontoUMLProblemsPanel ifAbsent: [ nil ].
	panel ifNil: [ ^ self ].
	panel check.

	self deny: panel isApplicable.
	self deny: ((OPOntoUMLProblemsPanel canvasSectionIn: editor layout) children includes: panel)
]

{ #category : 'tests - panel' }
OPOntoUMLCheckTest >> testSettingsOfferTheLanguage [

	| node |
	node := (SettingTree new
		         acceptableKeywords: #( #systemsettings );
		         yourself) nodeList detect: [ :each | each settingDeclaration name = #languageName ].

	self assert: node parentName equals: #openponk.
	self assert: node settingDeclaration label equals: 'OntoUML assistant language'
]

{ #category : 'helpers' }
OPOntoUMLCheckTest >> waitForLiveCheck [

	(Delay forMilliseconds: 450) wait.
	self currentWorld doOneCycle
]
