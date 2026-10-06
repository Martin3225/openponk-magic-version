"
Undoable step defined by two blocks, for MCP changes that have no command of their own in OpenPonk (e.g. changing the stereotype of an element).
"
Class {
	#name : 'OPMcpBlockCommand',
	#superclass : 'OPCommand',
	#instVars : [
		'executeBlock',
		'undoBlock'
	],
	#category : 'OpenPonk-MCP',
	#package : 'OpenPonk-MCP'
}

{ #category : 'instance creation' }
OPMcpBlockCommand class >> named: aString execute: anExecuteBlock undo: anUndoBlock [

	^ self new
		  description: aString;
		  setExecute: anExecuteBlock undo: anUndoBlock;
		  yourself
]

{ #category : 'executing' }
OPMcpBlockCommand >> execute [

	executeBlock value
]

{ #category : 'initialization' }
OPMcpBlockCommand >> setExecute: anExecuteBlock undo: anUndoBlock [

	executeBlock := anExecuteBlock.
	undoBlock := anUndoBlock
]

{ #category : 'executing' }
OPMcpBlockCommand >> undo [

	undoBlock value
]
