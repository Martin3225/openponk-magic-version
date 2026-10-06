"
Sets the stereotype Role of the selected classes, see OPOntoUMLStereotypeKeyCommand.
"
Class {
	#name : 'OPOntoUMLRoleKeyCommand',
	#superclass : 'OPOntoUMLStereotypeKeyCommand',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'activation' }
OPOntoUMLRoleKeyCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: self keyCombination for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPOntoUMLRoleKeyCommand class >> stereotypeName [

	^ 'Role'
]
