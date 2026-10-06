"
Chooses the palette tool Association, see OPOntoUMLPaletteKeyCommand.
"
Class {
	#name : 'OPOntoUMLAssociationToolKeyCommand',
	#superclass : 'OPOntoUMLPaletteKeyCommand',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'activation' }
OPOntoUMLAssociationToolKeyCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: self keyCombination for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPOntoUMLAssociationToolKeyCommand class >> paletteLabel [

	^ 'Association'
]
