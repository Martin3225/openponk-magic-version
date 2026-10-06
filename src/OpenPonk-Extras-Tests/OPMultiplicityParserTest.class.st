"
Tests of reading multiplicities, also through the properties form path of UML attributes and association ends.
"
Class {
	#name : 'OPMultiplicityParserTest',
	#superclass : 'TestCase',
	#category : 'OpenPonk-Extras-Tests',
	#package : 'OpenPonk-Extras-Tests'
}

{ #category : 'tests' }
OPMultiplicityParserTest >> testBounds [

	{
		('1' -> #( 1 1 )).
		('*' -> #( 0 '*' )).
		('0..1' -> #( 0 1 )).
		('1..*' -> #( 1 '*' )).
		('1...3' -> #( 1 3 )).
		('0.5..2.5' -> #( 0.5 2.5 )).
		('0,5...2,5' -> #( 0.5 2.5 )).
		(' 0.25 .. * ' -> #( 0.25 '*' )).
		('1.5' -> #( 1.5 1.5 )).
		('2.0..3' -> #( 2 3 )) } do: [ :each |
		self assert: (OPMultiplicityParser boundsFrom: each key) equals: each value ].
	self assert: (OPMultiplicityParser boundsFrom: '2.0..3') first isInteger
]

{ #category : 'tests' }
OPMultiplicityParserTest >> testInvalid [

	#( '' 'many' '1....3' '3..1' '-1..2' '1..2..3' '..2' 'a..b' '0.5..' ) do: [ :each |
		self should: [ OPMultiplicityParser boundsFrom: each ] raise: OPInvalidMultiplicity ]
]

{ #category : 'tests' }
OPMultiplicityParserTest >> testWriteThroughViewModels [

	| property association |
	property := OPUMLProperty new.
	OPUmlClassPropertyViewModel new writeMultiplicityFrom: '0,5...2' to: property.
	self assert: property lowerBound equals: 0.5.
	self assert: property upperBound equals: 2.
	self assert: property notationMultiplicityRange equals: '0.5..2'.
	association := OPUMLProperty new.
	OPUmlAssociationViewModel new writeMultiplicityFrom: '1...*' to: association.
	self assert: association notationAssociationMultiplicityRange equals: '1..*'.
	"Invalid text changes nothing (the user is informed)."
	OPUmlClassPropertyViewModel new writeMultiplicityFrom: 'many' to: property.
	self assert: property lowerBound equals: 0.5.
	self assert: property upperBound equals: 2
]
