"
One badge of OPOntoUMLProblemMarkers: where it is drawn (world coordinates) and the problems of its element.
"
Class {
	#name : 'OPOntoUMLProblemBadge',
	#superclass : 'Object',
	#instVars : [
		'center',
		'problems'
	],
	#category : 'OpenPonk-Extras-OntoUML-Problems',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Problems'
}

{ #category : 'accessing' }
OPOntoUMLProblemBadge >> center [

	^ center
]

{ #category : 'accessing' }
OPOntoUMLProblemBadge >> center: aPoint [

	center := aPoint
]

{ #category : 'accessing' }
OPOntoUMLProblemBadge >> color [

	^ Color fromHexString: (self isError
			   ifTrue: [ 'D93025' ]
			   ifFalse: [ 'E8A100' ])
]

{ #category : 'testing' }
OPOntoUMLProblemBadge >> isError [

	^ problems anySatisfy: [ :each | each isError ]
]

{ #category : 'accessing' }
OPOntoUMLProblemBadge >> label [

	^ problems size > 1
		  ifTrue: [ problems size printString ]
		  ifFalse: [ '!' ]
]

{ #category : 'accessing' }
OPOntoUMLProblemBadge >> problems [

	^ problems
]

{ #category : 'accessing' }
OPOntoUMLProblemBadge >> problems: aCollection [

	problems := aCollection
]

{ #category : 'accessing' }
OPOntoUMLProblemBadge >> tooltip [

	^ String cr join: (problems collect: [ :each | each title ])
]
