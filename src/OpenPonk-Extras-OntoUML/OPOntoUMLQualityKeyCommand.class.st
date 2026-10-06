"
Sets the stereotype Quality of the selected classes, see OPOntoUMLStereotypeKeyCommand.
"
Class {
	#name : 'OPOntoUMLQualityKeyCommand',
	#superclass : 'OPOntoUMLStereotypeKeyCommand',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'activation' }
OPOntoUMLQualityKeyCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: self keyCombination for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPOntoUMLQualityKeyCommand class >> stereotypeName [

	^ 'Quality'
]
