"
What the OntoUML assistant knows about OntoUML stereotypes: their groups and order for menus (sortals first, as students meet them), one-line descriptions with examples, colors from the OntoUML notation styles, and how to read the stereotype and a readable name of a model element.
"
Class {
	#name : 'OPOntoUMLStereotypeCatalog',
	#superclass : 'Object',
	#category : 'OpenPonk-Extras-OntoUML-Catalog',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Catalog'
}

{ #category : 'stereotypes' }
OPOntoUMLStereotypeCatalog class >> classGroups [
	"Group key -> class stereotype names, in the order they are offered."

	^ {
		  (#sortals -> #( 'Kind' 'SubKind' 'Role' 'Phase' 'Collective' 'Quantity' )).
		  (#nonSortals -> #( 'Category' 'RoleMixin' 'PhaseMixin' 'Mixin' )).
		  (#aspects -> #( 'Relator' 'Mode' 'Quality' )) }
]

{ #category : 'stereotypes' }
OPOntoUMLStereotypeCatalog class >> classStereotypeNames [

	^ self classGroups flatCollect: [ :each | each value ]
]

{ #category : 'stereotypes' }
OPOntoUMLStereotypeCatalog class >> descriptionOf: aStereotypeName [

	^ OPOntoUMLTexts at: ('stereotype.' , aStereotypeName) asSymbol
]

{ #category : 'naming' }
OPOntoUMLStereotypeCatalog class >> displayNameOf: anElement [
	"Name of a model element for the user: its name, 'Child → Person' for a generalization, 'belongs to (Car – Fleet)' or 'Car – Fleet' for an association."

	| unnamed name |
	unnamed := OPOntoUMLTexts at: #unnamed.
	anElement ifNil: [ ^ unnamed ].
	(anElement isKindOf: OPUMLGeneralization) ifTrue: [
		^ (self displayNameOf: anElement specific) , ' → ' , (self displayNameOf: anElement general) ].
	(anElement isKindOf: OPUMLGeneralizationSet) ifTrue: [
		^ anElement generalizations
			  ifEmpty: [ unnamed ]
			  ifNotEmpty: [ :generalizations |
			  (self displayNameOf: generalizations anyOne general) , ' {…}' ] ].
	name := [ anElement name ]
		        on: Error
		        do: [ nil ].
	(anElement isKindOf: OPUMLAssociation) ifTrue: [
		| ends |
		ends := [
		        (self displayNameOf: anElement memberEnds first type) , ' – '
		        , (self displayNameOf: anElement memberEnds second type) ]
			        on: Error
			        do: [ unnamed ].
		^ (name isNil or: [ name trimBoth isEmpty ])
			  ifTrue: [ ends ]
			  ifFalse: [ name trimBoth , ' (' , ends , ')' ] ].
	(name isNil or: [ name trimBoth isEmpty ]) ifFalse: [ ^ name trimBoth ].
	^ unnamed
]

{ #category : 'stereotypes' }
OPOntoUMLStereotypeCatalog class >> fillColorOf: aStereotypeName [
	"The fill color of classes with the stereotype in OntoUML diagrams (the user's style override, else the plugin's default), or nil."

	| plugin |
	plugin := OntoUMLPlugin new.
	[
	((OPNotationStyleRegistry default rulesForPlugin: plugin)
		 at: aStereotypeName
		 ifAbsent: [ nil ]) ifNotNil: [ :rules |
		(rules at: #fillColor ifAbsent: [ nil ]) ifNotNil: [ :color | ^ color ] ] ]
		on: Error
		do: [ "no overrides" ].
	^ [
	  (plugin defaultStyleSheet rules at: aStereotypeName ifAbsent: [ nil ])
		  ifNotNil: [ :rules | rules at: #fillColor ifAbsent: [ nil ] ] ]
		  on: Error
		  do: [ nil ]
]

{ #category : 'stereotypes' }
OPOntoUMLStereotypeCatalog class >> groupLabelOf: aGroupKey [

	^ OPOntoUMLTexts at: ('group.' , aGroupKey) asSymbol
]

{ #category : 'testing' }
OPOntoUMLStereotypeCatalog class >> isOntoUMLDiagram: aDiagramController [

	^ aDiagramController isNotNil and: [ self isOntoUMLModel: aDiagramController model ]
]

{ #category : 'testing' }
OPOntoUMLStereotypeCatalog class >> isOntoUMLModel: aModel [

	(aModel isNotNil and: [ aModel respondsTo: #profileApplications ]) ifFalse: [ ^ false ].
	^ aModel profileApplications anySatisfy: [ :each |
		  each appliedProfile isNotNil and: [ each appliedProfile name = 'OntoUML' ] ]
]

{ #category : 'stereotypes' }
OPOntoUMLStereotypeCatalog class >> isRelationStereotype: aStereotypeName [

	^ self relationStereotypeNames includes: aStereotypeName
]

{ #category : 'stereotypes' }
OPOntoUMLStereotypeCatalog class >> nameOfStereotypeClass: aClassOrNil [
	"OntoUMLKind -> 'Kind'."

	| name |
	aClassOrNil ifNil: [ ^ nil ].
	name := aClassOrNil name.
	^ (name beginsWith: 'OntoUML')
		  ifTrue: [ name allButFirst: 'OntoUML' size ]
		  ifFalse: [ name asString ]
]

{ #category : 'stereotypes' }
OPOntoUMLStereotypeCatalog class >> relationGroups [

	^ { (#relations
	   ->
	   #( 'Mediation' 'Material' 'Characterization' 'ComponentOf' 'MemberOf' 'SubCollectionOf'
	      'SubQuantityOf' 'Containment' 'Derivation' 'Formal' 'DomainFormal' )) }
]

{ #category : 'stereotypes' }
OPOntoUMLStereotypeCatalog class >> relationStereotypeNames [

	^ self relationGroups flatCollect: [ :each | each value ]
]

{ #category : 'stereotypes' }
OPOntoUMLStereotypeCatalog class >> stereotypeNameOf: anElement [
	"'Kind', 'Mediation'... or nil when the element has no OntoUML stereotype."

	(anElement respondsTo: #appliedStereotypes) ifFalse: [ ^ nil ].
	^ anElement appliedStereotypes
		  detect: [ :each | each isKindOf: OntoUMLElement ]
		  ifFound: [ :stereotype | self nameOfStereotypeClass: stereotype class ]
		  ifNone: [ nil ]
]

{ #category : 'shortcuts' }
OPOntoUMLStereotypeCatalog class >> shortcutLabelOf: aStereotypeName [
	"E.g. 'K', 'Shift+R', or nil (the menu font has no glyph for the shift arrow)."

	^ self shortcuts
		  detect: [ :each | each first = aStereotypeName ]
		  ifFound: [ :each |
			  each third
				  ifTrue: [ 'Shift+' , each second asUppercase asString ]
				  ifFalse: [ each second asUppercase asString ] ]
		  ifNone: [ nil ]
]

{ #category : 'shortcuts' }
OPOntoUMLStereotypeCatalog class >> shortcuts [
	"Stereotype name, key, with Shift. Single keys on the canvas set the stereotype of the selected classes (see OPOntoUMLStereotypeKeyCommand): the first letter of the name, or the second one when the first is taken (rElator, mOde, mIxin); Shift for the variant (RoleMixin, PhaseMixin, Collective, Quantity). M is left out: the canvas maximizes the window when M is released."

	^ #( #( 'Kind' $k false ) #( 'SubKind' $s false ) #( 'Role' $r false ) #( 'Phase' $p false )
	     #( 'Relator' $e false ) #( 'Category' $c false ) #( 'Quality' $q false ) #( 'Mode' $o false )
	     #( 'Mixin' $i false ) #( 'RoleMixin' $r true ) #( 'PhaseMixin' $p true )
	     #( 'Collective' $c true ) #( 'Quantity' $q true ) )
]

{ #category : 'stereotypes' }
OPOntoUMLStereotypeCatalog class >> swatchOf: aStereotypeNameOrNil [
	"Small icon: the fill color of the stereotype, a line for relations, an empty box for none."

	| form color |
	form := Form extent: 14 @ 14 depth: 32.
	form fillColor: Color transparent.
	(aStereotypeNameOrNil notNil and: [ self isRelationStereotype: aStereotypeNameOrNil ])
		ifTrue: [
			form getCanvas
				line: 1 @ 7
				to: 12 @ 7
				width: 2
				color: Color darkGray.
			^ form ].
	color := aStereotypeNameOrNil ifNotNil: [ self fillColorOf: aStereotypeNameOrNil ].
	form getCanvas
		fillRectangle: (1 @ 1 extent: 12 @ 12)
		color: (color ifNil: [ Color white ]).
	form getCanvas frameRectangle: (1 @ 1 extent: 12 @ 12) color: Color gray.
	^ form
]
