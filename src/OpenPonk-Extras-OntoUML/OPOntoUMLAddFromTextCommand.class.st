"
Opens OPOntoUMLTextDialog for the diagram: from the canvas context menu (also on an empty place), with Cmd+E / Ctrl+E, or from the Model menu of the editor.
"
Class {
	#name : 'OPOntoUMLAddFromTextCommand',
	#superclass : 'OPRoassalShapeCommand',
	#category : 'OpenPonk-Extras-OntoUML-Text',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Text'
}

{ #category : 'testing' }
OPOntoUMLAddFromTextCommand class >> canBeExecutedInContext: aToolContext [

	^ (super canBeExecutedInContext: aToolContext) and: [
		  OPOntoUMLStereotypeCatalog isOntoUMLDiagram: aToolContext diagramController ]
]

{ #category : 'activation' }
OPOntoUMLAddFromTextCommand class >> canvasCtrlShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: $e ctrl for: OPCanvasPresenter
]

{ #category : 'activation' }
OPOntoUMLAddFromTextCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: $e meta for: OPCanvasPresenter
]

{ #category : 'activation' }
OPOntoUMLAddFromTextCommand class >> contextMenuActivation [

	<classAnnotation>
	^ CmdContextMenuActivation byRootGroupItemOrder: 23 for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPOntoUMLAddFromTextCommand >> defaultMenuIconName [

	^ #add
]

{ #category : 'accessing' }
OPOntoUMLAddFromTextCommand >> defaultMenuItemName [

	^ OPOntoUMLTexts at: #'command.addFromText'
]

{ #category : 'execution' }
OPOntoUMLAddFromTextCommand >> execute [

	OPOntoUMLTextDialog openOn: diagramController
]
