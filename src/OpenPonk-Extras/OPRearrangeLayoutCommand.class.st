"
Layout menu command that arranges the diagram anew with as few crossings as it finds, see OPDiagramRearranger. Available in every diagram.
"
Class {
	#name : 'OPRearrangeLayoutCommand',
	#superclass : 'OPLayoutDiagramCommand',
	#category : 'OpenPonk-Extras-Layout',
	#package : 'OpenPonk-Extras',
	#tag : 'Layout'
}

{ #category : 'testing' }
OPRearrangeLayoutCommand class >> canBeExecutedInContext: aToolContext [

	^ true
]

{ #category : 'accessing' }
OPRearrangeLayoutCommand >> defaultMenuItemName [

	^ 'Rearrange (fewest crossings)'
]

{ #category : 'execution' }
OPRearrangeLayoutCommand >> execute [

	(OPDiagramRearranger on: diagramPresenter diagramController) rearrange
]
