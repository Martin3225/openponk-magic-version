"
Chooses the palette tool Generalization, see OPOntoUMLPaletteKeyCommand.
"
Class {
	#name : 'OPOntoUMLGeneralizationToolKeyCommand',
	#superclass : 'OPOntoUMLPaletteKeyCommand',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'activation' }
OPOntoUMLGeneralizationToolKeyCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: self keyCombination for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPOntoUMLGeneralizationToolKeyCommand class >> paletteLabel [

	^ 'Generalization'
]
