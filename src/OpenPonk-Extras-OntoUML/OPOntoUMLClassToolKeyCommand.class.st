"
Chooses the palette tool Class, see OPOntoUMLPaletteKeyCommand.
"
Class {
	#name : 'OPOntoUMLClassToolKeyCommand',
	#superclass : 'OPOntoUMLPaletteKeyCommand',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'activation' }
OPOntoUMLClassToolKeyCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: self keyCombination for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPOntoUMLClassToolKeyCommand class >> paletteLabel [

	^ 'Class'
]
