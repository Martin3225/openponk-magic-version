"
Tests of the text of generalization set labels.
"
Class {
	#name : 'OPGeneralizationSetLabelTest',
	#superclass : 'TestCase',
	#category : 'OpenPonk-Extras-Tests',
	#package : 'OpenPonk-Extras-Tests'
}

{ #category : 'helpers' }
OPGeneralizationSetLabelTest >> textForSets: aCollection [

	^ String streamContents: [ :stream |
		  aCollection
			  do: [ :each | OPUmlGeneralizationLabel new defaultTextForSet: each on: stream ]
			  separatedBy: [ stream << '; ' ] ]
]

{ #category : 'tests' }
OPGeneralizationSetLabelTest >> testAllCombinations [

	{
		(#( false false ) -> '{incomplete, overlapping}').
		(#( true false ) -> '{complete, overlapping}').
		(#( false true ) -> '{incomplete, disjoint}').
		(#( true true ) -> '{complete, disjoint}') } do: [ :each |
		self
			assert: (self textForSets: { (OPUMLGeneralizationSet new
					   isCovering: each key first;
					   isDisjoint: each key second;
					   yourself) })
			equals: each value ]
]

{ #category : 'tests' }
OPGeneralizationSetLabelTest >> testNamedSetsAndNilFlags [

	self
		assert: (self textForSets: {
					 (OPUMLGeneralizationSet new
						  name: 'byRole';
						  isCovering: true;
						  isDisjoint: true;
						  yourself).
					 OPUMLGeneralizationSet new })
		equals: 'byRole {complete, disjoint}; {incomplete, overlapping}'
]
