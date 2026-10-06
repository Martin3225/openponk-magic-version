Extension { #name : 'OPCanvasExporter' }

{ #category : '*OpenPonk-Extras-OntoUML' }
OPCanvasExporter >> export [
	"Override of OpenPonk-Spec: the same export, without the badges of the OntoUML check (OPOntoUMLProblemMarkers) in the picture."

	^ OPOntoUMLProblemMarkers hideOn: self diagramController during: [
		  | jobBlock |
		  self diagramController deselectAll.

		  jobBlock := [ :job |
		              job title: 'Exporting diagram'.
		              [ self exportInJob: job ] ensure: [
			              job progress: 0.8.
			              self canvas signalUpdate ] ].

		  silently ifTrue: [ ^ jobBlock value: Job new ].
		  jobBlock asJob run.

		  self showFinishedPopup ]
]
