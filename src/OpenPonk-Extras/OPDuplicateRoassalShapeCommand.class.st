"
Context menu command and Cmd+D / Ctrl+D shortcut that duplicates the selected diagram elements, see OPDiagramElementsDuplicator.
"
Class {
	#name : 'OPDuplicateRoassalShapeCommand',
	#superclass : 'OPRoassalShapeCommand',
	#category : 'OpenPonk-Extras-Duplicate',
	#package : 'OpenPonk-Extras',
	#tag : 'Duplicate'
}

{ #category : 'testing' }
OPDuplicateRoassalShapeCommand class >> canBeExecutedInContext: aToolContext [

	^ (super canBeExecutedInContext: aToolContext) and: [
		  aToolContext roassalShapes anySatisfy: [ :any | any canvas ~= any ] ]
]

{ #category : 'activation' }
OPDuplicateRoassalShapeCommand class >> canvasCtrlShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: $d ctrl for: OPCanvasPresenter
]

{ #category : 'activation' }
OPDuplicateRoassalShapeCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: $d meta for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPDuplicateRoassalShapeCommand >> defaultMenuIconName [

	^ #smallCopy
]

{ #category : 'accessing' }
OPDuplicateRoassalShapeCommand >> defaultMenuItemName [

	^ 'Duplicate'
]

{ #category : 'execution' }
OPDuplicateRoassalShapeCommand >> execute [

	(OPDiagramElementsDuplicator on: diagramController)
		duplicateRoassalShapes: roassalShapes.
	canvas signalUpdate
]
