"
Exporter for tests: instead of writing a file it records whether badges of the OntoUML check were on the canvas while exporting.
"
Class {
	#name : 'OPOntoUMLRecordingExporter',
	#superclass : 'OPCanvasExporter',
	#instVars : [
		'markersWereVisible'
	],
	#category : 'OpenPonk-Extras-OntoUML-Tests',
	#package : 'OpenPonk-Extras-OntoUML-Tests'
}

{ #category : 'exporting' }
OPOntoUMLRecordingExporter >> exportInJob: aJob [

	markersWereVisible := self canvas shapes anySatisfy: [ :each |
		                      each model isCollection and: [
			                      each model notEmpty and: [
				                      each model anyOne isKindOf: OPOntoUMLProblem ] ] ]
]

{ #category : 'accessing' }
OPOntoUMLRecordingExporter >> markersWereVisible [

	^ markersWereVisible
]
