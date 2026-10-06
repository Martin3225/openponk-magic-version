"
Sets the stereotype SubKind of the selected classes, see OPOntoUMLStereotypeKeyCommand.
"
Class {
	#name : 'OPOntoUMLSubKindKeyCommand',
	#superclass : 'OPOntoUMLStereotypeKeyCommand',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'activation' }
OPOntoUMLSubKindKeyCommand class >> canvasShortcutActivation [

	<classAnnotation>
	^ CmdShortcutActivation by: self keyCombination for: OPCanvasPresenter
]

{ #category : 'accessing' }
OPOntoUMLSubKindKeyCommand class >> stereotypeName [

	^ 'SubKind'
]
