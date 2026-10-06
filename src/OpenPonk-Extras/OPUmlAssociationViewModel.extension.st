Extension { #name : 'OPUmlAssociationViewModel' }

{ #category : '*OpenPonk-Extras' }
OPUmlAssociationViewModel >> writeMultiplicityFrom: aString to: aProperty [
	"Override of OpenPonk-ClassEditor: also '1...3', real numbers and a decimal comma; invalid text is reported instead of failing or being misread."

	OPMultiplicityParser write: aString to: aProperty
]
