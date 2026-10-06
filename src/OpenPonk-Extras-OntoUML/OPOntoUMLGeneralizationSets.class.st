"
Generalization sets the way students think about them: as subclasses of one parent that are disjoint or overlapping and complete or incomplete.

- #generalizationsForSelection: finds the generalizations meant by a selection in the diagram: selected generalization arrows, or selected subclasses (which are easier to click) with a common parent, or a parent with some of its subclasses, or a single parent alone (all its direct subclasses).
- #setGeneralizations:disjoint:covering: creates the set, or changes the set they already are in (or extend it), instead of adding a second one.
- #putPhasesIntoDisjointCompleteSetOf: and #makeSetsOfPhaseDisjointComplete: are the quick fixes of the model check: phases always form a {disjoint, complete} set.

Every change is one undoable step.
"
Class {
	#name : 'OPOntoUMLGeneralizationSets',
	#superclass : 'Object',
	#instVars : [
		'diagramController',
		'builder'
	],
	#category : 'OpenPonk-Extras-OntoUML-GeneralizationSets',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'GeneralizationSets'
}

{ #category : 'instance creation' }
OPOntoUMLGeneralizationSets class >> on: aDiagramController [

	^ self new
		  setDiagramController: aDiagramController;
		  yourself
]

{ #category : 'model' }
OPOntoUMLGeneralizationSets >> allGeneralizations [

	^ (diagramController model packagedElements select: [ :each | self isGeneralizable: each ])
		  flatCollect: [ :each | each generalizations ] as: IdentitySet
]

{ #category : 'model' }
OPOntoUMLGeneralizationSets >> commonSetOf: aCollectionOfGeneralizations [
	"The set the generalizations are to go to: the only set that contains all of them, or the only set that contains some of them while the others are in no set; nil when a new set is needed."

	| sets |
	sets := (aCollectionOfGeneralizations flatCollect: [ :each | each generalizationSets ]) asIdentitySet.
	sets size = 1 ifFalse: [ ^ nil ].
	^ (aCollectionOfGeneralizations allSatisfy: [ :each |
		   each generalizationSets isEmpty or: [ each generalizationSets includes: sets anyOne ] ])
		  ifTrue: [ sets anyOne ]
		  ifFalse: [ nil ]
]

{ #category : 'model' }
OPOntoUMLGeneralizationSets >> generalizationsForSelection: aCollectionOfModels [
	"Generalizations (with one common general) meant by the selected model elements, or an empty collection when the selection does not say."

	| generalizations classes parents |
	generalizations := aCollectionOfModels select: [ :each | each isKindOf: OPUMLGeneralization ].
	generalizations ifNotEmpty: [
		^ (generalizations collect: [ :each | each general ]) asIdentitySet size = 1
			  ifTrue: [ generalizations asArray ]
			  ifFalse: [ #(  ) ] ].
	classes := (aCollectionOfModels select: [ :each | self isGeneralizable: each ]) asArray.
	classes ifEmpty: [ ^ #(  ) ].
	classes size = 1 ifTrue: [ ^ self specializationsOf: classes first ].
	"A parent selected together with some of its subclasses."
	classes
		detect: [ :parent |
			(classes copyWithout: parent) allSatisfy: [ :each |
				each generalizations anySatisfy: [ :generalization | generalization general == parent ] ] ]
		ifFound: [ :parent |
			^ ((classes copyWithout: parent) collect: [ :each |
				   each generalizations detect: [ :generalization | generalization general == parent ] ])
				  asArray ].
	"Subclasses with exactly one common direct parent."
	parents := classes allButFirst
		           inject: (classes first generalizations collect: [ :each | each general ]) asIdentitySet
		           into: [ :common :each |
			           common
				           select: [ :parent |
				           each generalizations anySatisfy: [ :generalization | generalization general == parent ] ]
				           thenCollect: [ :parent | parent ] ].
	parents size = 1 ifFalse: [ ^ #(  ) ].
	^ (classes collect: [ :each |
		   each generalizations detect: [ :generalization | generalization general == parents anyOne ] ])
		  asArray
]

{ #category : 'model' }
OPOntoUMLGeneralizationSets >> isGeneralizable: aModelElement [
	"Classes, data types... (the UML metamodel of OpenPonk has no common superclass for them)."

	^ (aModelElement respondsTo: #generalizations) and: [
		  (aModelElement isKindOf: OPUMLGeneralization) not and: [
			  (aModelElement isKindOf: OPUMLGeneralizationSet) not ] ]
]

{ #category : 'phases' }
OPOntoUMLGeneralizationSets >> makeSetsOfPhaseDisjointComplete: aPhase [
	"Quick fix: the sets the phase is in become {disjoint, complete}."

	| sets |
	sets := (aPhase generalizations flatCollect: [ :each | each generalizationSets ]) asIdentitySet
		        reject: [ :each | each isDisjoint == true and: [ each isCovering == true ] ].
	sets ifEmpty: [ ^ self ].
	builder inTransactionLabeled: (OPOntoUMLTexts at: #'fix.makeDC') do: [
		sets do: [ :each | builder generalizationSet: each disjoint: true covering: true ] ].
	self updateCanvas
]

{ #category : 'phases' }
OPOntoUMLGeneralizationSets >> putPhasesIntoDisjointCompleteSetOf: aPhase [
	"Quick fix: the phase and its sibling phases not yet in a set form a {disjoint, complete} set."

	| generalization siblings set |
	generalization := aPhase generalizations
		                  detect: [ :each | each general isNotNil ]
		                  ifNone: [ ^ nil ].
	siblings := (self specializationsOf: generalization general) select: [ :each |
		            each generalizationSets isEmpty and: [
			            (OPOntoUMLStereotypeCatalog stereotypeNameOf: each specific) = 'Phase' ] ].
	(siblings includes: generalization) ifFalse: [ siblings := siblings copyWith: generalization ].
	builder inTransactionLabeled: (OPOntoUMLTexts at: #'fix.createDCSet') do: [
		set := builder
			       newGeneralizationSetOf: siblings
			       disjoint: true
			       covering: true
			       named: nil ].
	self updateCanvas.
	^ set
]

{ #category : 'changing' }
OPOntoUMLGeneralizationSets >> removeFromSet: aCollectionOfGeneralizations [

	| set |
	set := (self commonSetOf: aCollectionOfGeneralizations) ifNil: [ ^ self ].
	builder inTransactionLabeled: (OPOntoUMLTexts at: #'gs.remove') do: [
		builder
			removeGeneralizations: (aCollectionOfGeneralizations select: [ :each |
					 each generalizationSets includes: set ])
			fromSet: set ].
	self updateCanvas
]

{ #category : 'changing' }
OPOntoUMLGeneralizationSets >> setGeneralizations: aCollectionOfGeneralizations disjoint: isDisjoint covering: isCovering [
	"Create the set of the generalizations, or change (and extend) the set they are already in."

	| set |
	aCollectionOfGeneralizations ifEmpty: [ ^ nil ].
	set := self commonSetOf: aCollectionOfGeneralizations.
	builder inTransactionLabeled: (OPOntoUMLTexts at: #'gs.change') do: [
		set
			ifNil: [
				set := builder
					       newGeneralizationSetOf: aCollectionOfGeneralizations
					       disjoint: isDisjoint
					       covering: isCovering
					       named: nil ]
			ifNotNil: [
				| missing |
				missing := aCollectionOfGeneralizations reject: [ :each | each generalizationSets includes: set ].
				missing ifNotEmpty: [ builder addGeneralizations: missing toSet: set ].
				(set isDisjoint == isDisjoint and: [ set isCovering == isCovering ]) ifFalse: [
					builder generalizationSet: set disjoint: isDisjoint covering: isCovering ] ] ].
	self updateCanvas.
	^ set
]

{ #category : 'initialization' }
OPOntoUMLGeneralizationSets >> setDiagramController: aDiagramController [

	diagramController := aDiagramController.
	builder := OPDiagramBuilder on: aDiagramController
]

{ #category : 'model' }
OPOntoUMLGeneralizationSets >> specializationsOf: aClassifier [
	"Generalizations whose general is aClassifier."

	^ (self allGeneralizations select: [ :each | each general == aClassifier ]) asArray
]

{ #category : 'private' }
OPOntoUMLGeneralizationSets >> updateCanvas [

	diagramController canvas ifNotNil: [ :canvas | canvas signalUpdate ]
]
