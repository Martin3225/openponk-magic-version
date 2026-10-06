"
Layout menu command that removes overlaps of nodes and labels while keeping the arrangement, see OPDiagramTidier. Available in every diagram, unlike the layouts of the plugins.
"
Class {
	#name : 'OPTidyLayoutCommand',
	#superclass : 'OPLayoutDiagramCommand',
	#category : 'OpenPonk-Extras-Layout',
	#package : 'OpenPonk-Extras',
	#tag : 'Layout'
}

{ #category : 'testing' }
OPTidyLayoutCommand class >> canBeExecutedInContext: aToolContext [

	^ true
]

{ #category : 'accessing' }
OPTidyLayoutCommand >> defaultMenuItemName [

	^ 'Tidy (remove overlaps)'
]

{ #category : 'execution' }
OPTidyLayoutCommand >> execute [

	(OPDiagramTidier on: diagramPresenter diagramController) tidy
]
