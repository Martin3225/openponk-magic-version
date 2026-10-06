"
Sets the stereotype Phase of the selected classes, see OPOntoUMLStereotypeKeyCommand.
"
Class {
	#name : 'OPOntoUMLPhaseKeyCommand',
	#superclass : 'OPOntoUMLStereotypeKeyCommand',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'activation' }
OPOntoUMLPhaseKeyCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: self keyCombination for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPOntoUMLPhaseKeyCommand class >> stereotypeName [

	^ 'Phase'
]
