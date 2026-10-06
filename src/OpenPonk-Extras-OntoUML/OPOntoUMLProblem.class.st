"
One problem found by OPOntoUMLChecker: the model element it concerns, whether it is an error (breaks an OntoUML rule) or a warning (an anti-pattern or a recommendation, may be fine), a short title, an explanation of what is wrong and how to fix it, a link to the OntoUML documentation and possibly a quick fix.
"
Class {
	#name : 'OPOntoUMLProblem',
	#superclass : 'Object',
	#instVars : [
		'element',
		'severity',
		'rule',
		'title',
		'explanation',
		'documentationUrl',
		'fix',
		'source',
		'alsoFixed'
	],
	#category : 'OpenPonk-Extras-OntoUML-Problems',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Problems'
}

{ #category : 'accessing' }
OPOntoUMLProblem >> alsoFixed [
	"Elements with the same problem caused by this one (e.g. sub-roles of a role without a relator)."

	^ alsoFixed ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OPOntoUMLProblem >> alsoFixes: anElement [

	(self alsoFixed includes: anElement) ifFalse: [ alsoFixed := self alsoFixed copyWith: anElement ]
]

{ #category : 'accessing' }
OPOntoUMLProblem >> documentationUrl [

	^ documentationUrl
]

{ #category : 'accessing' }
OPOntoUMLProblem >> documentationUrl: aStringOrNil [

	documentationUrl := aStringOrNil
]

{ #category : 'accessing' }
OPOntoUMLProblem >> element [
	"The model element (class, association, generalization or generalization set)."

	^ element
]

{ #category : 'accessing' }
OPOntoUMLProblem >> element: aModelElement [

	element := aModelElement
]

{ #category : 'accessing' }
OPOntoUMLProblem >> elementName [

	^ OPOntoUMLStereotypeCatalog displayNameOf: element
]

{ #category : 'accessing' }
OPOntoUMLProblem >> explanation [
	"What is wrong and how to fix it; names the elements fixed along with this one."

	self alsoFixed ifEmpty: [ ^ explanation ].
	^ explanation , ' ' , (OPOntoUMLTexts at: #alsoFixes with: { ', ' join: ((self alsoFixed collect: [ :each |
					      OPOntoUMLStereotypeCatalog displayNameOf: each ]) asSortedCollection: [ :a :b |
					     a asLowercase <= b asLowercase ]) })
]

{ #category : 'accessing' }
OPOntoUMLProblem >> explanation: aString [

	explanation := aString
]

{ #category : 'accessing' }
OPOntoUMLProblem >> fix [
	"An OPOntoUMLQuickFix or nil."

	^ fix
]

{ #category : 'accessing' }
OPOntoUMLProblem >> fix: aQuickFixOrNil [

	fix := aQuickFixOrNil
]

{ #category : 'testing' }
OPOntoUMLProblem >> isError [

	^ severity = #error
]

{ #category : 'testing' }
OPOntoUMLProblem >> isWarning [

	^ severity = #warning
]

{ #category : 'printing' }
OPOntoUMLProblem >> printOn: aStream [

	aStream << severity << ' ' << rule << ': ' << title asString
]

{ #category : 'accessing' }
OPOntoUMLProblem >> rule [
	"Symbol naming what is wrong, e.g. #roleWithoutRelator; stable across languages."

	^ rule
]

{ #category : 'accessing' }
OPOntoUMLProblem >> rule: aSymbol [

	rule := aSymbol
]

{ #category : 'accessing' }
OPOntoUMLProblem >> severity [
	"#error or #warning."

	^ severity
]

{ #category : 'accessing' }
OPOntoUMLProblem >> severity: aSymbol [

	severity := aSymbol
]

{ #category : 'accessing' }
OPOntoUMLProblem >> severityLabel [

	^ OPOntoUMLTexts at: ('severity.' , severity) asSymbol
]

{ #category : 'accessing' }
OPOntoUMLProblem >> source [
	"Name of the OpenPonk verification that found the problem, or #OPOntoUMLChecker for own checks."

	^ source
]

{ #category : 'accessing' }
OPOntoUMLProblem >> source: aSymbol [

	source := aSymbol
]

{ #category : 'accessing' }
OPOntoUMLProblem >> title [

	^ title
]

{ #category : 'accessing' }
OPOntoUMLProblem >> title: aString [

	title := aString
]
