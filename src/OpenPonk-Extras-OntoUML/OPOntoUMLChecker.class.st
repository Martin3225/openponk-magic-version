"
I check an OntoUML model and answer OPOntoUMLProblems that a student can act on.

The rules themselves are the verifications and anti-pattern detections of OpenPonk (OpenPonk-OntoUML-Verifications). I run them object by object, so an element in the middle of editing (a relation without an end...) only skips its own check instead of opening a debugger, and I translate their results into plain explanations (see OPOntoUMLTexts) with element names, allowed stereotypes and, where possible, a quick fix. Results saying the same thing twice (the two role dependency rules, allowed subtypes and supertypes) are merged.

I add a few checks of my own for things the verifications skip: classes and relations without a stereotype and duplicate names.

Errors break OntoUML rules. Warnings (anti-patterns and recommendations) point at places worth a second look and may be fine; they are only answered when asked for (#includeWarnings:).
"
Class {
	#name : 'OPOntoUMLChecker',
	#superclass : 'Object',
	#instVars : [
		'model',
		'includeWarnings'
	],
	#category : 'OpenPonk-Extras-OntoUML-Problems',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Problems'
}

{ #category : 'instance creation' }
OPOntoUMLChecker class >> on: aPackage [

	^ self new
		  model: aPackage;
		  yourself
]

{ #category : 'checking' }
OPOntoUMLChecker class >> problemsIn: aPackage [

	^ (self on: aPackage) problems
]

{ #category : 'checking' }
OPOntoUMLChecker class >> problemsIn: aPackage includeWarnings: aBoolean [

	^ (self on: aPackage)
		  includeWarnings: aBoolean;
		  problems
]

{ #category : 'private - model' }
OPOntoUMLChecker >> allGeneralizations [

	^ self classes flatCollect: [ :each | each generalizations ]
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> antipatternProblemFrom: aMessage [

	| abbreviation rule |
	abbreviation := aMessage verification class abbreviation.
	rule := (abbreviation first asLowercase asString , abbreviation allButFirst) asSymbol.
	(OPOntoUMLTexts at: (rule , '.title') asSymbol) = (rule , '.title') ifTrue: [
		^ self genericProblemFrom: aMessage ].
	^ self
		  problem: rule
		  for: aMessage objectReference
		  from: aMessage
		  with: { (self nameOf: aMessage objectReference) }
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> characterizedProblemFrom: aMessage [

	| element |
	element := aMessage objectReference.
	^ self
		  problem: ((aMessage messageText includesSubstring: 'multiplicity')
				   ifTrue: [ #characterizationMultiplicity ]
				   ifFalse: [ #notCharacterized ])
		  for: element
		  from: aMessage
		  with: {
				  (self nameOf: element).
				  (self stereotypeOf: element) }
]

{ #category : 'private - model' }
OPOntoUMLChecker >> ancestorsOf: aClassifier [
	"All direct and indirect generals (safe for cycles)."

	| ancestors toVisit |
	ancestors := IdentitySet new.
	toVisit := OrderedCollection withAll: ([ aClassifier generalizations ]
			            on: Error
			            do: [ #(  ) ]).
	[ toVisit isEmpty ] whileFalse: [
		| general |
		general := toVisit removeFirst general.
		(general isNotNil and: [ (ancestors includes: general) not ]) ifTrue: [
			ancestors add: general.
			toVisit addAll: general generalizations ] ].
	^ ancestors
]

{ #category : 'private' }
OPOntoUMLChecker >> cascadingRules [
	"Rules whose violation is inherited: a role below a role without a relator has none either."

	^ #( #roleWithoutRelator #noIdentity )
]

{ #category : 'private' }
OPOntoUMLChecker >> withoutCascades: aCollectionOfProblems [
	"Report the cause only: a problem of a cascading rule is dropped when an ancestor of its element has the same problem; the explanation of the ancestor's problem names the elements it fixes too."

	| dropped |
	dropped := IdentitySet new.
	self cascadingRules do: [ :rule |
		| byElement |
		byElement := IdentityDictionary new.
		aCollectionOfProblems do: [ :each | each rule = rule ifTrue: [ byElement at: each element put: each ] ].
		byElement keysAndValuesDo: [ :element :problem |
			| causes |
			causes := (self ancestorsOf: element) select: [ :each |
				          (byElement includesKey: each) and: [
					          ((self ancestorsOf: each) anySatisfy: [ :ancestor | byElement includesKey: ancestor ]) not ] ].
			causes ifNotEmpty: [
				dropped add: problem.
				causes do: [ :each | (byElement at: each) alsoFixes: element ] ] ] ].
	^ aCollectionOfProblems reject: [ :each | dropped includes: each ]
]

{ #category : 'private - fixes' }
OPOntoUMLChecker >> chooseStereotypeFixFor: anElement [

	^ OPOntoUMLQuickFix
		  label: (OPOntoUMLTexts at: #'fix.chooseStereotype')
		  do: [ :diagramController |
			  (diagramController controllerForModel: anElement ifNone: [ nil ]) ifNotNil: [ :controller |
				  OPOntoUMLStereotypeMenu new
					  diagramController: diagramController;
					  controllers: { controller };
					  popUp ] ]
]

{ #category : 'private - model' }
OPOntoUMLChecker >> classes [

	^ model packagedElements select: [ :each | each class == OPUMLClass ]
]

{ #category : 'private - fixes' }
OPOntoUMLChecker >> createPhaseSetFixFor: aPhase [

	^ OPOntoUMLQuickFix
		  label: (OPOntoUMLTexts at: #'fix.createDCSet')
		  do: [ :diagramController |
			  (OPOntoUMLGeneralizationSets on: diagramController) putPhasesIntoDisjointCompleteSetOf: aPhase ]
]

{ #category : 'private - own checks' }
OPOntoUMLChecker >> customProblems [

	| problems named |
	problems := OrderedCollection new.
	self classes do: [ :each |
		(self hasOntoUMLStereotype: each) ifFalse: [
			problems add: ((self problem: #noStereotype for: each severity: #error with: { (self nameOf: each) })
					 fix: (self chooseStereotypeFixFor: each);
					 yourself) ].
		(each name isNil or: [ each name trimBoth isEmpty ]) ifTrue: [
			problems add: (self problem: #unnamed for: each severity: #warning with: #(  )) ] ].
	named := (self classes reject: [ :each | each name isNil or: [ each name trimBoth isEmpty ] ])
		         groupedBy: [ :each | each name trimBoth asLowercase ].
	named do: [ :sameName |
		sameName size > 1 ifTrue: [
			sameName do: [ :each |
				problems add: (self problem: #duplicateName for: each severity: #warning with: { (self nameOf: each) }) ] ] ].
	(model packagedElements select: [ :each | each isKindOf: OPUMLAssociation ]) do: [ :each |
		(self hasOntoUMLStereotype: each) ifFalse: [
			problems add: ((self problem: #associationNoStereotype for: each severity: #warning with: { (self nameOf: each) })
					 fix: (self chooseStereotypeFixFor: each);
					 yourself) ] ].
	^ problems
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> documentationOf: aMessage [

	^ [ aMessage documentationReference ifNotNil: [ :url | url asString ifEmpty: [ nil ] ] ]
		  on: Error
		  do: [ nil ]
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> generalizationProblemFrom: aMessage [

	| generalization generalStereotype allowed |
	generalization := aMessage objectReference.
	generalStereotype := Verification getStereotypeClass: generalization general.
	allowed := (AllowedSubtypesVerification validSubtypes at: generalStereotype ifAbsent: [ #(  ) ])
		           collect: [ :each | OPOntoUMLStereotypeCatalog nameOfStereotypeClass: each ].
	^ self
		  problem: #invalidGeneralization
		  for: generalization
		  from: aMessage
		  with: {
				  (self nameOf: generalization specific).
				  (self nameOf: generalization general).
				  (self stereotypeOf: generalization specific).
				  (self stereotypeOf: generalization general).
				  (self listOf: allowed) }
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> genericProblemFrom: aMessage [
	"A result of a verification without an own explanation: its text as OpenPonk words it."

	^ OPOntoUMLProblem new
		  element: aMessage objectReference;
		  severity: (self severityOf: aMessage);
		  rule: aMessage verification class name;
		  title: (OPOntoUMLTexts at: #'generic.title' with: {
						   (self nameOf: aMessage objectReference).
						   aMessage messageText asString });
		  explanation: aMessage messageText asString;
		  documentationUrl: (self documentationOf: aMessage);
		  source: aMessage verification class name;
		  yourself
]

{ #category : 'private - model' }
OPOntoUMLChecker >> hasOntoUMLStereotype: anElement [

	^ (OPOntoUMLStereotypeCatalog stereotypeNameOf: anElement) isNotNil
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> identityProblemFrom: aMessage [

	| text element |
	text := aMessage messageText asString.
	element := aMessage objectReference.
	^ self
		  problem: ((text includesSubstring: 'loop')
				   ifTrue: [ #generalizationLoop ]
				   ifFalse: [
					   (text includesSubstring: 'multiple')
						   ifTrue: [ #multipleIdentity ]
						   ifFalse: [ #noIdentity ] ])
		  for: element
		  from: aMessage
		  with: {
				  (self nameOf: element).
				  (self stereotypeOf: element) }
]

{ #category : 'accessing' }
OPOntoUMLChecker >> includeWarnings [

	^ includeWarnings
]

{ #category : 'accessing' }
OPOntoUMLChecker >> includeWarnings: aBoolean [

	includeWarnings := aBoolean
]

{ #category : 'initialization' }
OPOntoUMLChecker >> initialize [

	super initialize.
	includeWarnings := false
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> listOf: aCollectionOfNames [

	^ ', ' join: (aCollectionOfNames reject: [ :each | each isNil ])
]

{ #category : 'private - fixes' }
OPOntoUMLChecker >> makePhaseSetDisjointCompleteFixFor: aPhase [

	^ OPOntoUMLQuickFix
		  label: (OPOntoUMLTexts at: #'fix.makeDC')
		  do: [ :diagramController |
			  (OPOntoUMLGeneralizationSets on: diagramController) makeSetsOfPhaseDisjointComplete: aPhase ]
]

{ #category : 'private' }
OPOntoUMLChecker >> merged: aCollectionOfProblems [
	"One problem per element and rule (e.g. both role dependency verifications report a role without a mediation)."

	| seen |
	seen := Set new.
	^ aCollectionOfProblems select: [ :each |
		  | key |
		  key := { each element identityHash. each element. each rule }.
		  (seen includes: key)
			  ifTrue: [ false ]
			  ifFalse: [
				  seen add: key.
				  true ] ]
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> messageHandlers [
	"Verification class name -> selector translating its results."

	^ Dictionary new
		  at: #IdentityRequiredVerification put: #identityProblemFrom:;
		  at: #RoleMediationDependencyVerification put: #roleProblemFrom:;
		  at: #RelationDependencyVerification put: #roleProblemFrom:;
		  at: #RelatorMediationDependencyVerification put: #relatorProblemFrom:;
		  at: #CharacterizedVerification put: #characterizedProblemFrom:;
		  at: #PartOfGeneralizationSetVerification put: #phaseSetProblemFrom:;
		  at: #AllowedSubtypesVerification put: #generalizationProblemFrom:;
		  at: #AllowedSupertypesVerification put: #generalizationProblemFrom:;
		  at: #RelationSourceVerification put: #relationSourceProblemFrom:;
		  at: #RelationTargetVerification put: #relationTargetProblemFrom:;
		  yourself
]

{ #category : 'accessing' }
OPOntoUMLChecker >> model [

	^ model
]

{ #category : 'accessing' }
OPOntoUMLChecker >> model: aPackage [

	model := aPackage
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> nameOf: anElement [

	^ OPOntoUMLStereotypeCatalog displayNameOf: anElement
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> phaseSetProblemFrom: aMessage [

	| phase notInSet |
	phase := aMessage objectReference.
	notInSet := aMessage messageText includesSubstring: 'has to be part'.
	^ (self
		   problem: (notInSet
				    ifTrue: [ #phaseNotInSet ]
				    ifFalse: [ #phaseSetNotDC ])
		   for: phase
		   from: aMessage
		   with: { (self nameOf: phase) })
		  fix: (notInSet
				   ifTrue: [ self createPhaseSetFixFor: phase ]
				   ifFalse: [ self makePhaseSetDisjointCompleteFixFor: phase ]);
		  yourself
]

{ #category : 'private' }
OPOntoUMLChecker >> problem: aRule for: anElement from: aMessage with: anArray [

	^ (self problem: aRule for: anElement severity: (self severityOf: aMessage) with: anArray)
		  documentationUrl: (self documentationOf: aMessage);
		  source: aMessage verification class name;
		  yourself
]

{ #category : 'private' }
OPOntoUMLChecker >> problem: aRule for: anElement severity: aSeverity with: anArray [

	^ OPOntoUMLProblem new
		  element: anElement;
		  severity: aSeverity;
		  rule: aRule;
		  title: (OPOntoUMLTexts at: (aRule , '.title') asSymbol with: anArray);
		  explanation: (OPOntoUMLTexts at: (aRule , '.text') asSymbol with: anArray);
		  source: self class name;
		  yourself
]

{ #category : 'private' }
OPOntoUMLChecker >> problemFromMessage: aMessage [

	| selector |
	selector := self messageHandlers
		            at: aMessage verification class name
		            ifAbsent: [
			            aMessage verification class packageTag name = 'Antipattern-Classes'
				            ifTrue: [ #antipatternProblemFrom: ]
				            ifFalse: [ #genericProblemFrom: ] ].
	^ [ self perform: selector with: aMessage ]
		  on: Error
		  do: [ self genericProblemFrom: aMessage ]
]

{ #category : 'checking' }
OPOntoUMLChecker >> problems [
	"Errors first, then warnings (if asked for); each group by element name."

	| problems |
	problems := OrderedCollection new.
	self rawMessages do: [ :each |
		([ self problemFromMessage: each ]
			 on: Error
			 do: [ nil ]) ifNotNil: [ :problem | problems add: problem ] ].
	problems addAll: self customProblems.
	problems := self withoutCascades: (self merged: problems).
	includeWarnings ifFalse: [ problems := problems select: [ :each | each isError ] ].
	^ problems asArray sort: [ :a :b |
		  a isError = b isError
			  ifTrue: [ a elementName asLowercase <= b elementName asLowercase ]
			  ifFalse: [ a isError ] ]
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> rawMessages [
	"Results of the OpenPonk verifications, each object checked separately so that a half-built element only skips its own check."

	| objects messages |
	objects := self verifiedObjects.
	messages := OrderedCollection new.
	self verifications do: [ :verification |
		objects do: [ :object |
			[ messages addAll: (verification verify: object withModel: objects) ]
				on: Error
				do: [ "e.g. a relation without an end while it is being drawn" ] ] ].
	^ messages
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> relationEndProblemFrom: aMessage rule: aRule [

	| association verification end relationStereotype allowed |
	association := aMessage objectReference.
	verification := aMessage verification.
	end := verification getVerifiedEnd: association.
	relationStereotype := Verification getStereotypeClass: association.
	allowed := (verification validStereotypesForEnd at: relationStereotype ifAbsent: [ #(  ) ])
		           collect: [ :each | OPOntoUMLStereotypeCatalog nameOfStereotypeClass: each ].
	^ self
		  problem: aRule
		  for: association
		  from: aMessage
		  with: {
				  (self nameOf: end).
				  (self stereotypeOf: end).
				  (OPOntoUMLStereotypeCatalog nameOfStereotypeClass: relationStereotype).
				  (self listOf: allowed) }
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> relationSourceProblemFrom: aMessage [

	^ self relationEndProblemFrom: aMessage rule: #invalidRelationSource
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> relationTargetProblemFrom: aMessage [

	^ self relationEndProblemFrom: aMessage rule: #invalidRelationTarget
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> relatorProblemFrom: aMessage [

	^ self
		  problem: ((aMessage messageText includesSubstring: 'total multiplicity')
				   ifTrue: [ #relatorOneSide ]
				   ifFalse: [ #relatorWithoutMediation ])
		  for: aMessage objectReference
		  from: aMessage
		  with: { (self nameOf: aMessage objectReference) }
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> roleProblemFrom: aMessage [

	^ self
		  problem: #roleWithoutRelator
		  for: aMessage objectReference
		  from: aMessage
		  with: { (self nameOf: aMessage objectReference) }
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> severityOf: aMessage [

	^ (aMessage isKindOf: VerificationMessageError)
		  ifTrue: [ #error ]
		  ifFalse: [ #warning ]
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> stereotypeOf: anElement [

	^ (OPOntoUMLStereotypeCatalog stereotypeNameOf: anElement) ifNil: [ '' ]
]

{ #category : 'private - messages' }
OPOntoUMLChecker >> verifications [

	| controller verifications |
	controller := VerificationController new.
	verifications := controller getVerifications asOrderedCollection.
	includeWarnings ifTrue: [ verifications addAll: controller getAntiPatternVerifications ].
	^ verifications select: [ :each |
		  [ VerificationFrameworkSettings getInstance getSettingFor: each ]
			  on: Error
			  do: [ true ] ]
]

{ #category : 'private - model' }
OPOntoUMLChecker >> verifiedObjects [
	"What OpenPonk's own Verify model checks: top-level classes and associations, their generalizations and generalization sets."

	^ [ VerificationController new getVerifiedObjects: model ]
		  on: Error
		  do: [
			  model packagedElements select: [ :each |
				  (each isKindOf: OPUMLClass) or: [ each isKindOf: OPUMLAssociation ] ] ]
]
