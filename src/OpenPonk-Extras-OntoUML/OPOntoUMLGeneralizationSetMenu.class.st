"
Menu for putting the selected subclasses (or generalization arrows) of one parent into a generalization set. The four kinds of sets are explained by what they mean for the parent's instances (exactly one of them, at most one...), with {disjoint, complete} recommended for phases. If the generalizations already are in a set, the set is changed instead of adding another one, and can be dissolved.
"
Class {
	#name : 'OPOntoUMLGeneralizationSetMenu',
	#superclass : 'OPOntoUMLPopupMenu',
	#category : 'OpenPonk-Extras-OntoUML-Menus',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Menus'
}

{ #category : 'building' }
OPOntoUMLGeneralizationSetMenu >> buildMenu [

	| generalizations sets current allPhases parentName |
	generalizations := self generalizations.
	generalizations ifEmpty: [
		self inform: (OPOntoUMLTexts at: #'gs.selectFirst').
		^ nil ].
	sets := OPOntoUMLGeneralizationSets on: diagramController.
	current := (sets commonSetOf: generalizations) ifNotNil: [ :set |
		           (generalizations allSatisfy: [ :each | each generalizationSets includes: set ])
			           ifTrue: [ set ] ].
	allPhases := generalizations allSatisfy: [ :each |
		             (OPOntoUMLStereotypeCatalog stereotypeNameOf: each specific) = 'Phase' ].
	parentName := OPOntoUMLStereotypeCatalog displayNameOf: generalizations first general.
	^ MenuMorph new
		  addTitle: (OPOntoUMLTexts at: #'gs.title' with: {
						   parentName.
						   (', ' join: (generalizations collect: [ :each |
								     OPOntoUMLStereotypeCatalog displayNameOf: each specific ])) });
		  in: [ :menu |
			  self kinds do: [ :kind |
				  | note |
				  note := OPOntoUMLTexts at: ('gs.' , kind first , '.note') asSymbol with: { parentName }.
				  (current notNil and: [
					   current isDisjoint == kind second and: [ current isCovering == kind third ] ])
					  ifTrue: [ note := note , '  ' , (OPOntoUMLTexts at: #'menu.current') ].
				  (allPhases and: [ kind first = 'dc' ]) ifTrue: [
					  note := note , '  ' , (OPOntoUMLTexts at: #'gs.recommendedForPhases') ].
				  self
					  addItem: (OPOntoUMLTexts at: ('gs.' , kind first) asSymbol)
					  note: note
					  icon: nil
					  to: menu
					  selector: #setDisjoint:covering:
					  arguments: kind allButFirst ].
			  current ifNotNil: [
				  menu addLine.
				  self
					  addItem: (OPOntoUMLTexts at: #'gs.remove')
					  note: nil
					  icon: nil
					  to: menu
					  selector: #removeFromSet
					  arguments: #(  ) ] ];
		  yourself
]

{ #category : 'accessing' }
OPOntoUMLGeneralizationSetMenu >> generalizations [

	^ (OPOntoUMLGeneralizationSets on: diagramController) generalizationsForSelection:
		  (controllers collect: [ :each | each model ])
]

{ #category : 'accessing' }
OPOntoUMLGeneralizationSetMenu >> kinds [
	"Key, isDisjoint, isCovering."

	^ #( #( 'dc' true true ) #( 'di' true false ) #( 'oc' false true ) #( 'oi' false false ) )
]

{ #category : 'applying' }
OPOntoUMLGeneralizationSetMenu >> removeFromSet [

	(OPOntoUMLGeneralizationSets on: diagramController) removeFromSet: self generalizations
]

{ #category : 'applying' }
OPOntoUMLGeneralizationSetMenu >> setDisjoint: isDisjoint covering: isCovering [

	(OPOntoUMLGeneralizationSets on: diagramController)
		setGeneralizations: self generalizations
		disjoint: isDisjoint
		covering: isCovering
]
