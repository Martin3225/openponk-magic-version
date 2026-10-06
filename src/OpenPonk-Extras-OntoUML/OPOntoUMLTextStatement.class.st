"
One line of the text for adding elements (see OPOntoUMLTextParser):

- #class: names with a stereotype, optionally with parents and a generalization set, e.g. Child, Adult : Phase -> Person {disjoint, complete};
- #generalization: names with parents (and a set) only, e.g. Child, Adult -> Person {dc};
- #relation: source, target, optional multiplicities, stereotype and name, e.g. Study 1..* --mediation-- 1 Student : studies.
"
Class {
	#name : 'OPOntoUMLTextStatement',
	#superclass : 'Object',
	#instVars : [
		'kind',
		'line',
		'names',
		'stereotype',
		'parents',
		'setText',
		'source',
		'sourceMultiplicity',
		'target',
		'targetMultiplicity',
		'relationStereotype',
		'label'
	],
	#category : 'OpenPonk-Extras-OntoUML-Text',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Text'
}

{ #category : 'testing' }
OPOntoUMLTextStatement >> isClass [

	^ kind = #class
]

{ #category : 'testing' }
OPOntoUMLTextStatement >> isGeneralization [

	^ kind = #generalization
]

{ #category : 'testing' }
OPOntoUMLTextStatement >> isRelation [

	^ kind = #relation
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> kind [

	^ kind
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> kind: aSymbol [

	kind := aSymbol
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> label [

	^ label
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> label: aStringOrNil [

	label := aStringOrNil
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> line [

	^ line
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> line: anInteger [

	line := anInteger
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> names [

	^ names ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> names: aCollection [

	names := aCollection asArray
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> parents [

	^ parents ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> parents: aCollection [

	parents := aCollection asArray
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> relationStereotype [

	^ relationStereotype
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> relationStereotype: aStringOrNil [

	relationStereotype := aStringOrNil
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> setText [
	"The text inside {} after the parents, or nil."

	^ setText
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> setText: aStringOrNil [

	setText := aStringOrNil
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> source [

	^ source
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> source: aString [

	source := aString
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> sourceMultiplicity [

	^ sourceMultiplicity
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> sourceMultiplicity: aStringOrNil [

	sourceMultiplicity := aStringOrNil
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> stereotype [

	^ stereotype
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> stereotype: aStringOrNil [

	stereotype := aStringOrNil
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> target [

	^ target
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> target: aString [

	target := aString
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> targetMultiplicity [

	^ targetMultiplicity
]

{ #category : 'accessing' }
OPOntoUMLTextStatement >> targetMultiplicity: aStringOrNil [

	targetMultiplicity := aStringOrNil
]
