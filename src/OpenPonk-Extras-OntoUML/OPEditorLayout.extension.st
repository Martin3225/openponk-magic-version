Extension { #name : 'OPEditorLayout' }

{ #category : '*OpenPonk-Extras-OntoUML' }
OPEditorLayout >> applyOn: anEditor [
	"Override of OpenPonk-Spec: the same layout, plus the OntoUML problems panel between the canvas and the zoom toolbar of OntoUML editors (see OPOntoUMLProblemsPanel class>>#addTo:of:)."

	anEditor canvasPresenter needRebuild: false.
	^ anEditor layout: (OPOntoUMLProblemsPanel addTo: (self spLayoutFor: anEditor) of: anEditor)
]
