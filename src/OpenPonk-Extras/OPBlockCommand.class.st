"
Undoable step defined by two blocks, for changes that have no command of their own in OpenPonk (e.g. changing the stereotype of an element).
"
Class {
	#name : 'OPBlockCommand',
	#superclass : 'OPCommand',
	#instVars : [
		'executeBlock',
		'undoBlock'
	],
	#category : 'OpenPonk-Extras-Builder',
	#package : 'OpenPonk-Extras',
	#tag : 'Builder'
}

{ #category : 'instance creation' }
OPBlockCommand class >> named: aString execute: anExecuteBlock undo: anUndoBlock [

	^ self new
		  description: aString;
		  setExecute: anExecuteBlock undo: anUndoBlock;
		  yourself
]

{ #category : 'executing' }
OPBlockCommand >> execute [

	executeBlock value
]

{ #category : 'initialization' }
OPBlockCommand >> setExecute: anExecuteBlock undo: anUndoBlock [

	executeBlock := anExecuteBlock.
	undoBlock := anUndoBlock
]

{ #category : 'executing' }
OPBlockCommand >> undo [

	undoBlock value
]
