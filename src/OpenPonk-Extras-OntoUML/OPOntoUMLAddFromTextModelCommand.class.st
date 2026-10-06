"
Add from text... in the Model menu of OntoUML editors (see OPOntoUMLTextDialog), where students look for things to do with the model.
"
Class {
	#name : 'OPOntoUMLAddFromTextModelCommand',
	#superclass : 'OPModelCommand',
	#category : 'OpenPonk-Extras-OntoUML-Text',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Text'
}

{ #category : 'testing' }
OPOntoUMLAddFromTextModelCommand class >> canBeExecutedInEditor: anEditor [

	^ OPOntoUMLStereotypeCatalog isOntoUMLDiagram: anEditor diagramController
]

{ #category : 'activation' }
OPOntoUMLAddFromTextModelCommand class >> modelMenuActivation [

	<classAnnotation>
	^ OPModelMenuActivation byItemOf: OPModelBasicMenuGroup order: 5 for: OPEditor
]

{ #category : 'accessing' }
OPOntoUMLAddFromTextModelCommand >> defaultMenuIcon [

	^ self iconNamed: #add
]

{ #category : 'accessing' }
OPOntoUMLAddFromTextModelCommand >> defaultMenuItemName [

	^ OPOntoUMLTexts at: #'command.addFromText'
]

{ #category : 'execution' }
OPOntoUMLAddFromTextModelCommand >> execute [

	OPOntoUMLTextDialog openOn: self diagramController
]
