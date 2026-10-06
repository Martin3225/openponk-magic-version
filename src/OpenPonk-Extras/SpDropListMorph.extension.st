Extension { #name : 'SpDropListMorph' }

{ #category : '*OpenPonk-Extras' }
SpDropListMorph >> listMorphClass [
	"Override of Spec2-Adapters-Morphic (originally ^ PluggableIconListMorph): same list, plus hover highlight."

	^ OPHoverIconListMorph
]
