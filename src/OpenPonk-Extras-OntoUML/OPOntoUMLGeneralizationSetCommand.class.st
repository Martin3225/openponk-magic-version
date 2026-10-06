"
Context menu item and Cmd+G / Ctrl+G shortcut that open the generalization set menu (OPOntoUMLGeneralizationSetMenu) for the selected subclasses or generalizations of a UML or OntoUML class diagram.
"
Class {
	#name : 'OPOntoUMLGeneralizationSetCommand',
	#superclass : 'OPRoassalShapeCommand',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'testing' }
OPOntoUMLGeneralizationSetCommand class >> canBeExecutedInContext: aToolContext [

	^ (super canBeExecutedInContext: aToolContext) and: [
		  (aToolContext diagramController model isKindOf: OPUMLPackage) and: [
			  aToolContext models anySatisfy: [ :each |
				  (each isKindOf: OPUMLGeneralization) or: [ each respondsTo: #generalizations ] ] ] ]
]

{ #category : 'activation' }
OPOntoUMLGeneralizationSetCommand class >> canvasCtrlShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: $g ctrl for: OPCanvasPresenter
]

{ #category : 'activation' }
OPOntoUMLGeneralizationSetCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: $g meta for: OPCanvasPresenter
]

{ #category : 'activation' }
OPOntoUMLGeneralizationSetCommand class >> contextMenuActivation [

	<classAnnotation>
	^ CmdContextMenuActivation byRootGroupItemOrder: 22 for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPOntoUMLGeneralizationSetCommand >> defaultMenuIconName [

	^ #hierarchy
]

{ #category : 'accessing' }
OPOntoUMLGeneralizationSetCommand >> defaultMenuItemName [

	^ OPOntoUMLTexts at: #'command.generalizationSet'
]

{ #category : 'execution' }
OPOntoUMLGeneralizationSetCommand >> execute [

	OPOntoUMLGeneralizationSetMenu new
		diagramController: diagramController;
		controllers: controllers;
		popUp
]
