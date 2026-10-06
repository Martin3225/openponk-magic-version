"
Undoable change of navigability of a UML association end. The association view model moves the end between the association and the opposite class, which then shows or hides it as an attribute.
"
Class {
	#name : 'OPUmlNavigabilityCommand',
	#superclass : 'OPCommand',
	#instVars : [
		'viewModel',
		'end',
		'oldValue',
		'newValue'
	],
	#category : 'OpenPonk-Extras-Duplicate',
	#package : 'OpenPonk-Extras',
	#tag : 'Duplicate'
}

{ #category : 'instance creation' }
OPUmlNavigabilityCommand class >> viewModel: anAssociationViewModel end: aProperty navigable: aBoolean [

	^ self new
		  setViewModel: anAssociationViewModel
		  end: aProperty
		  navigable: aBoolean
]

{ #category : 'accessing' }
OPUmlNavigabilityCommand >> defaultDescription [

	^ 'Change navigability'
]

{ #category : 'executing' }
OPUmlNavigabilityCommand >> execute [

	self write: newValue
]

{ #category : 'initialization' }
OPUmlNavigabilityCommand >> setViewModel: anAssociationViewModel end: aProperty navigable: aBoolean [

	viewModel := anAssociationViewModel.
	end := aProperty.
	oldValue := aProperty isNavigable.
	newValue := aBoolean
]

{ #category : 'executing' }
OPUmlNavigabilityCommand >> undo [

	self write: oldValue
]

{ #category : 'private' }
OPUmlNavigabilityCommand >> write: aBoolean [

	end isNavigable = aBoolean ifTrue: [ ^ self ].
	viewModel writeNavigability: aBoolean to: end.
	viewModel modelChanged
]
