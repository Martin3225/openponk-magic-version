"
Sets the stereotype Quantity of the selected classes, see OPOntoUMLStereotypeKeyCommand.
"
Class {
	#name : 'OPOntoUMLQuantityKeyCommand',
	#superclass : 'OPOntoUMLStereotypeKeyCommand',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'activation' }
OPOntoUMLQuantityKeyCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: self keyCombination for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPOntoUMLQuantityKeyCommand class >> stereotypeName [

	^ 'Quantity'
]
