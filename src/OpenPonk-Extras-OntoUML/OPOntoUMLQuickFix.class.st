"
A one-click fix offered with a problem of the model check, e.g. creating the {disjoint, complete} set of phases. The block gets the diagram controller and makes its changes as one undoable step.
"
Class {
	#name : 'OPOntoUMLQuickFix',
	#superclass : 'Object',
	#instVars : [
		'label',
		'block'
	],
	#category : 'OpenPonk-Extras-OntoUML-Problems',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Problems'
}

{ #category : 'instance creation' }
OPOntoUMLQuickFix class >> label: aString do: aOneArgBlock [

	^ self new
		  setLabel: aString block: aOneArgBlock;
		  yourself
]

{ #category : 'applying' }
OPOntoUMLQuickFix >> applyIn: aDiagramController [

	block value: aDiagramController
]

{ #category : 'accessing' }
OPOntoUMLQuickFix >> label [

	^ label
]

{ #category : 'initialization' }
OPOntoUMLQuickFix >> setLabel: aString block: aOneArgBlock [

	label := aString.
	block := aOneArgBlock
]
