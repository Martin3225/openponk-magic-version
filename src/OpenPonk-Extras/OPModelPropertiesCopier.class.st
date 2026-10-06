"
I copy user-visible properties from one domain model element to another of the same kind, never sharing mutable values between them. Structure (owner, contained elements, identity, relationship ends) is left to the creation path that made the target.

- UML elements (OPUMLMetaElement): an explicit list of features (name, visibility, flags, type, multiplicities, default value), owned comments, operation parameters, applied stereotypes with their tagged values and, for associations, their ends (role names, multiplicities, aggregation, navigability). References to other elements (type, tagged values) keep pointing at the originals.
- Other models (OPModelObject based notations): instance variables holding plain values (strings, symbols, numbers, booleans, colors, points...).
"
Class {
	#name : 'OPModelPropertiesCopier',
	#superclass : 'Object',
	#category : 'OpenPonk-Extras-Duplicate',
	#package : 'OpenPonk-Extras',
	#tag : 'Duplicate'
}

{ #category : 'copying' }
OPModelPropertiesCopier >> copyFrom: aSource to: aTarget [

	(aSource isNil or: [ aTarget isNil or: [ aSource == aTarget ] ])
		ifTrue: [ ^ self ].
	(aSource isKindOf: OPUMLMetaElement)
		ifTrue: [ self copyUmlFrom: aSource to: aTarget ]
		ifFalse: [ self copyValuesFrom: aSource to: aTarget ]
]

{ #category : 'copying' }
OPModelPropertiesCopier >> copyFromController: aSourceController toController: aTargetController [

	self copyFrom: aSourceController model to: aTargetController model.
	(aSourceController model isKindOf: OPUMLAssociation) ifTrue: [
		self copyUmlAssociationEndsFrom: aSourceController to: aTargetController ]
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> copyUmlAssociationEndsFrom: aSourceController to: aTargetController [
	"The duplicate association already has its own ends typed by the duplicated classes (same order as the original). Copy role names, multiplicities, aggregation etc. and navigability, which the view model turns into an attribute shown in the owning class."

	| sourceEnds targetEnds |
	sourceEnds := aSourceController model memberEnds asArray.
	targetEnds := aTargetController model memberEnds asArray.
	sourceEnds size = targetEnds size ifFalse: [ ^ self ].
	sourceEnds with: targetEnds do: [ :sourceEnd :targetEnd |
		self copyUmlFrom: sourceEnd to: targetEnd except: #( #type ).
		sourceEnd isNavigable = targetEnd isNavigable ifFalse: [
			self
				setNavigability: sourceEnd isNavigable
				of: targetEnd
				in: aTargetController ] ]
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> copyUmlCommentsFrom: aSource to: aTarget [

	((aSource respondsTo: #ownedComments) and: [
		 aTarget respondsTo: #ownedComments ]) ifFalse: [ ^ self ].
	aSource ownedComments do: [ :each |
		aTarget ownedComments add: (OPUMLComment new
				 body: each body copy;
				 yourself) ]
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> copyUmlFeature: aSelector from: aSource to: aTarget [

	| mutator value |
	mutator := aSelector asMutator.
	((aSource respondsTo: aSelector) and: [ aTarget respondsTo: mutator ])
		ifFalse: [ ^ self ].
	value := aSource perform: aSelector.
	(value isCollection and: [ value isString not ]) ifTrue: [
		^ self copyUmlCollectionFeature: aSelector values: value to: aTarget ].
	aTarget perform: mutator with: (self copyOfValue: value)
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> copyUmlCollectionFeature: aSelector values: aCollection to: aTarget [
	"Fill the target's own collection (UML to-many links keep their opposites consistent) instead of sharing the source's one."

	| own |
	own := aTarget perform: aSelector.
	own ifNil: [
		^ aTarget perform: aSelector asMutator with: (aCollection collect: [ :each |
				   self copyOfValue: each ]) ].
	own removeAll: own copy.
	aCollection do: [ :each | own add: (self copyOfValue: each) ]
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> copyUmlFrom: aSource to: aTarget [

	self copyUmlFrom: aSource to: aTarget except: #(  )
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> copyUmlFrom: aSource to: aTarget except: excludedFeatures [

	(self umlValueFeatures copyWithoutAll: excludedFeatures) do: [ :each |
		self copyUmlFeature: each from: aSource to: aTarget ].
	self umlOwnedValueSpecificationFeatures do: [ :each |
		self copyUmlValueSpecification: each from: aSource to: aTarget ].
	self copyUmlCommentsFrom: aSource to: aTarget.
	self copyUmlParametersFrom: aSource to: aTarget.
	self copyUmlStereotypesFrom: aSource to: aTarget
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> copyUmlParametersFrom: aSource to: aTarget [

	((aSource respondsTo: #ownedParameters) and: [
		 aTarget respondsTo: #ownedParameters ]) ifFalse: [ ^ self ].
	aSource ownedParameters do: [ :each |
		| parameter |
		parameter := each class new.
		self copyUmlFrom: each to: parameter.
		aTarget ownedParameters add: parameter ]
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> copyUmlStereotype: aStereotype [
	"Fresh application of the same stereotype with the same tagged values (they live in shared generalizations, so go through the profile metaclass like #applyStereotype: does). The base_* link is set when the copy is applied."

	| copy |
	copy := aStereotype class new.
	aStereotype umlMetaClass allAttributes do: [ :each |
		(each name beginsWith: 'base_') ifFalse: [
			self copyUmlFeature: each name asSymbol from: aStereotype to: copy ] ].
	^ copy
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> copyUmlStereotypesFrom: aSource to: aTarget [

	((aSource respondsTo: #appliedStereotypes) and: [
		 aTarget respondsTo: #applyStereotype: ]) ifFalse: [ ^ self ].
	aTarget appliedStereotypes copy do: [ :each |
		aTarget unapplyStereotype: each ].
	aSource appliedStereotypes do: [ :each |
		(self isStereotypeApplication: each)
			ifTrue: [ aTarget applyStereotype: (self copyUmlStereotype: each) ]
			ifFalse: [ aTarget appliedStereotypes add: each ] ]
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> isStereotypeApplication: anObject [
	"A real application has a base_* link to the element it extends; anything else (e.g. a stereotype definition put directly into the list) is kept as a reference."

	^ [
	  anObject umlMetaClass allAttributes anySatisfy: [ :each |
		  each name beginsWith: 'base_' ] ]
		  on: Error
		  do: [ false ]
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> copyUmlValueSpecification: aSelector from: aSource to: aTarget [

	| mutator value copy |
	mutator := aSelector asMutator.
	((aSource respondsTo: aSelector) and: [ aTarget respondsTo: mutator ])
		ifFalse: [ ^ self ].
	value := aSource perform: aSelector.
	value ifNil: [ ^ aTarget perform: mutator with: nil ].
	copy := value class new.
	self copyUmlFrom: value to: copy.
	#( #value #bodies #languages ) do: [ :each |
		self copyUmlFeature: each from: value to: copy ].
	aTarget perform: mutator with: copy
]

{ #category : 'private - values' }
OPModelPropertiesCopier >> copyValuesFrom: aSource to: aTarget [

	aSource class allInstVarNames do: [ :each |
		| value |
		value := aSource instVarNamed: each.
		((self isStructureVariable: each) not and: [
			 (self isPlainValue: value) and: [
				 aTarget class allInstVarNames includes: each ] ]) ifTrue: [
			aTarget instVarNamed: each put: value copy ] ]
]

{ #category : 'private' }
OPModelPropertiesCopier >> copyOfValue: anObject [
	"Strings and plain collections of values are copied so that original and duplicate never share them; anything else (model references, enumeration literals...) is shared."

	anObject isString ifTrue: [ ^ anObject isSymbol ifTrue: [ anObject ] ifFalse: [ anObject copy ] ].
	((anObject isKindOf: SequenceableCollection) and: [
		 anObject allSatisfy: [ :each | self isPlainValue: each ] ])
		ifTrue: [ ^ anObject copy ].
	^ anObject
]

{ #category : 'private - values' }
OPModelPropertiesCopier >> isPlainValue: anObject [

	^ anObject isNil or: [
		  anObject isString or: [
			  anObject isNumber or: [
				  anObject isCharacter or: [
					  anObject == true or: [
						  anObject == false or: [
							  anObject isColor or: [
								  anObject isPoint or: [
									  (anObject isKindOf: Magnitude) and: [
										  (anObject isKindOf: LookupKey) not ] ] ] ] ] ] ] ] ]
]


{ #category : 'private - values' }
OPModelPropertiesCopier >> isStructureVariable: aName [

	^ #( #owner #elements #uuid #announcer #ownedElements #source #target
	     #diagramElement #viewModel ) includes: aName asSymbol
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> setNavigability: aBoolean of: anEnd in: anAssociationController [
	"Undoable, so that undoing the duplication also removes the attribute the view model shows for a navigable end."

	| viewModel command |
	viewModel := anAssociationController viewModel.
	(viewModel respondsTo: #writeNavigability:to:) ifFalse: [ ^ self ].
	command := OPUmlNavigabilityCommand
		           viewModel: viewModel
		           end: anEnd
		           navigable: aBoolean.
	anAssociationController undoManager
		ifNil: [ command execute ]
		ifNotNil: [ :undoManager | undoManager execute: command ]
]

{ #category : 'testing' }
OPModelPropertiesCopier >> shouldDuplicateInnerModel: aModel [
	"Association ends shown as attributes of a class belong to the association; they are recreated when the association itself is duplicated."

	^ ((aModel isKindOf: OPUMLProperty) and: [ aModel association isNotNil ]) not
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> umlOwnedValueSpecificationFeatures [

	^ #( #lowerValue #upperValue #defaultValue )
]

{ #category : 'private - uml' }
OPModelPropertiesCopier >> umlValueFeatures [

	^ #( #name #visibility #isAbstract #isStatic #isLeaf #isDerived
	     #isDerivedUnion #isReadOnly #isOrdered #isUnique #isID
	     #aggregation #isActive #isQuery #concurrency #direction
	     #isFinalSpecialization #type )
]
