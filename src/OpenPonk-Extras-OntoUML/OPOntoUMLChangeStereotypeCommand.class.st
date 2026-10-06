"
Context menu item and Cmd+T / Ctrl+T shortcut that open the stereotype menu (OPOntoUMLStereotypeMenu) for the selected classes or relations of an OntoUML diagram.
"
Class {
	#name : 'OPOntoUMLChangeStereotypeCommand',
	#superclass : 'OPRoassalShapeCommand',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'testing' }
OPOntoUMLChangeStereotypeCommand class >> canBeExecutedInContext: aToolContext [

	^ (super canBeExecutedInContext: aToolContext) and: [
		  (OPOntoUMLStereotypeCatalog isOntoUMLDiagram: aToolContext diagramController) and: [
			  aToolContext models anySatisfy: [ :each |
				  each class == OPUMLClass or: [ each isKindOf: OPUMLAssociation ] ] ] ]
]

{ #category : 'activation' }
OPOntoUMLChangeStereotypeCommand class >> canvasCtrlShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: $t ctrl for: OPCanvasPresenter
]

{ #category : 'activation' }
OPOntoUMLChangeStereotypeCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: $t meta for: OPCanvasPresenter
]

{ #category : 'activation' }
OPOntoUMLChangeStereotypeCommand class >> contextMenuActivation [

	<classAnnotation>
	^ CmdContextMenuActivation byRootGroupItemOrder: 21 for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPOntoUMLChangeStereotypeCommand >> defaultMenuIcon [

	^ OntoUMLIcons ontoumlIcon
]

{ #category : 'accessing' }
OPOntoUMLChangeStereotypeCommand >> defaultMenuItemName [

	^ OPOntoUMLTexts at: #'command.changeStereotype'
]

{ #category : 'execution' }
OPOntoUMLChangeStereotypeCommand >> execute [

	OPOntoUMLStereotypeMenu new
		diagramController: diagramController;
		controllers: controllers;
		popUp
]
