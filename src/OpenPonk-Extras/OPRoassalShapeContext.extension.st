Extension { #name : 'OPRoassalShapeContext' }

{ #category : '*OpenPonk-Extras' }
OPRoassalShapeContext >> roassalShapes: aCollection [
	"Override of OpenPonk-Spec: shapes without a controller are left out. The selection of the canvas can still hold the shape of an element that is gone (e.g. a selected relation whose creation was undone); looking up its controller failed, and with it every keyboard shortcut of the canvas until something else was clicked."

	roassalShapes := aCollection select: [ :each |
		                 (self diagramController controllerForRoassalShape: each ifNone: [ nil ]) isNotNil ].
	controllers := roassalShapes collect: [ :each | self diagramController controllerForRoassalShape: each ]
]
