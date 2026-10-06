"
The MCP tools of OpenPonk and their implementation.

Each tool runs in the UI process (OpenPonk is a Morphic application; the HTTP server answers in its own processes) and every change of a diagram goes through the project's undo manager as one labelled step. Errors never reach the UI as a debugger: tool errors (OPMcpToolError) and unexpected ones are answered as tool results with isError: true.

Projects are addressed by name or uuid, diagrams by name or 1-based index, elements by the ids get_diagram answers (uuids of their models). Element types are labels of the diagram's palette.
"
Class {
	#name : 'OPMcpTools',
	#superclass : 'Object',
	#instVars : [
		'definitions'
	],
	#category : 'OpenPonk-MCP',
	#package : 'OpenPonk-MCP'
}

{ #category : 'schema' }
OPMcpTools >> argBoolean: aDescription [

	^ OrderedDictionary new
		  at: 'type' put: 'boolean';
		  at: 'description' put: aDescription;
		  yourself
]

{ #category : 'schema' }
OPMcpTools >> argNumber: aDescription [

	^ OrderedDictionary new
		  at: 'type' put: 'number';
		  at: 'description' put: aDescription;
		  yourself
]

{ #category : 'schema' }
OPMcpTools >> argObject: aDescription [

	^ OrderedDictionary new
		  at: 'type' put: 'object';
		  at: 'description' put: aDescription;
		  at: 'additionalProperties' put: true;
		  yourself
]

{ #category : 'schema' }
OPMcpTools >> argString: aDescription [

	^ OrderedDictionary new
		  at: 'type' put: 'string';
		  at: 'description' put: aDescription;
		  yourself
]

{ #category : 'schema' }
OPMcpTools >> argStrings: aDescription [

	^ OrderedDictionary new
		  at: 'type' put: 'array';
		  at: 'items' put: (Dictionary new
				   at: 'type' put: 'string';
				   yourself);
		  at: 'description' put: aDescription;
		  yourself
]

{ #category : 'private - arguments' }
OPMcpTools >> arguments: aDictionary at: aKey [

	^ aDictionary at: aKey ifAbsent: [
		  OPMcpToolError signal: 'Missing argument "' , aKey , '"' ]
]

{ #category : 'private - arguments' }
OPMcpTools >> arguments: aDictionary numberAt: aKey [

	| value |
	value := aDictionary at: aKey ifAbsent: [ ^ nil ].
	value ifNil: [ ^ nil ].
	value isNumber ifTrue: [ ^ value ].
	^ [ value asString asNumber ]
		  on: Error
		  do: [ OPMcpToolError signal: '"' , aKey , '" must be a number' ]
]

{ #category : 'private - arguments' }
OPMcpTools >> arguments: aDictionary stringsAt: aKey [

	| value |
	value := self arguments: aDictionary at: aKey.
	value isString ifTrue: [ ^ { value } ].
	(value isCollection and: [ value allSatisfy: [ :each | each isString ] ])
		ifFalse: [ OPMcpToolError signal: '"' , aKey , '" must be a list of ids' ].
	^ value asArray
]

{ #category : 'private - json' }
OPMcpTools >> boundsOf: aDiagramElement into: aDictionary [
	"Position and size as the user sees them: x, y is the top-left corner of the shape."

	| rectangle |
	rectangle := self displayedRectangleOf: aDiagramElement.
	rectangle ifNil: [ ^ self ].
	aDictionary
		at: 'x' put: rectangle left floor;
		at: 'y' put: rectangle top floor;
		at: 'width' put: rectangle width rounded;
		at: 'height' put: rectangle height rounded
]

{ #category : 'private' }
OPMcpTools >> boundsOf: aDiagramElement withTopLeft: aPoint extent: anExtent [
	"OPNodeBounds of OpenPonk keep the centre of the shape (Roassal positions shapes by their centre)."

	^ OPNodeBounds withPosition: aPoint + (anExtent / 2) floor extent: anExtent
]

{ #category : 'private - json' }
OPMcpTools >> displayedRectangleOf: aDiagramElement [
	"The rendered shape when there is one (some shapes size themselves to their content), otherwise the stored bounds."

	| bounds |
	(aDiagramElement isRendered and: [ aDiagramElement roassalShape isNotNil ]) ifTrue: [
		^ aDiagramElement roassalShape encompassingRectangle ].
	bounds := [ aDiagramElement bounds ]
		          on: Error
		          do: [ nil ].
	bounds ifNil: [ ^ nil ].
	^ Rectangle center: bounds position extent: bounds extent
]

{ #category : 'private' }
OPMcpTools >> placeTopLeftOf: aDiagramElement at: aPoint [
	"Move the shape so that its drawn top-left corner is at aPoint (directly; for freshly created elements)."

	| delta |
	delta := self topLeftCorrectionOf: aDiagramElement to: aPoint.
	delta = (0 @ 0) ifTrue: [ ^ self ].
	aDiagramElement bounds: (OPNodeBounds
			 withPosition: aDiagramElement bounds position + delta
			 extent: aDiagramElement bounds extent).
	aDiagramElement updateRenderFromSelf
]

{ #category : 'private' }
OPMcpTools >> topLeftCorrectionOf: aDiagramElement to: aPoint [

	| rectangle |
	(aDiagramElement bounds isNil or: [ aDiagramElement isRendered not ]) ifTrue: [ ^ 0 @ 0 ].
	rectangle := self displayedRectangleOf: aDiagramElement.
	rectangle ifNil: [ ^ 0 @ 0 ].
	^ aPoint - rectangle topLeft floor
]

{ #category : 'definitions' }
OPMcpTools >> buildDefinitions [

	| project diagram |
	project := 'project'
	           -> (self argString:
			            'Project name or id from list_projects. Optional when exactly one project is open.').
	diagram := 'diagram'
	           -> (self argString:
			            'Diagram name or 1-based index within the project. Defaults to the diagram shown in the editor.').
	^ {
		  (self
			   tool: 'list_projects'
			   description:
			   'List OpenPonk projects open in this OpenPonk instance, with their diagrams and notations.'
			   arguments: {  }
			   required: #(  )
			   selector: #listProjects:).
		  (self
			   tool: 'list_notations'
			   description:
			   'List notations (plugins) that create_project accepts, e.g. "UML Class Editor", "ER Diagram", "BPMN".'
			   arguments: {  }
			   required: #(  )
			   selector: #listNotations:).
		  (self
			   tool: 'create_project'
			   description:
			   'Create a new project with one empty model and diagram of the given notation and open it in a new OpenPonk window.'
			   arguments: {
					   ('name' -> (self argString: 'Name of the project and its model.')).
					   ('notation' -> (self argString: 'Notation name (or a unique part of it) from list_notations.')) }
			   required: #( 'name' 'notation' )
			   selector: #createProject:).
		  (self
			   tool: 'open_project'
			   description: 'Open an OpenPonk project file (.opp) in a new window.'
			   arguments: { ('path' -> (self argString: 'Absolute path of the .opp file.')) }
			   required: #( 'path' )
			   selector: #openProject:).
		  (self
			   tool: 'save_project'
			   description:
			   'Save a project to its .opp file, or to the given path (required when the project was never saved).'
			   arguments: {
					   project.
					   ('path' -> (self argString: 'Absolute path of the .opp file to write. Optional.')) }
			   required: #(  )
			   selector: #saveProject:).
		  (self
			   tool: 'get_diagram'
			   description:
			   'Describe a diagram: every element with its id, type, name, label, position (x, y of the top-left corner) and size, nesting (parent) and, for edges, source and target ids.'
			   arguments: {
					   project.
					   diagram }
			   required: #(  )
			   selector: #getDiagram:).
		  (self
			   tool: 'list_element_types'
			   description:
			   'List element types that can be created in a diagram (labels of its palette). kind "node" is created by create_element, kind "edge" by connect_elements. topLevel false means the node must be created inside a parent element (e.g. a UML attribute inside a class).'
			   arguments: {
					   project.
					   diagram }
			   required: #(  )
			   selector: #listElementTypes:).
		  (self
			   tool: 'create_element'
			   description:
			   'Create a node of the given type (a palette label from list_element_types), optionally named, positioned, or inside a parent element. Answers the new element.'
			   arguments: {
					   project.
					   diagram.
					   ('type' -> (self argString: 'Palette label, e.g. "Class", "Attribute", "Regular Entity".')).
					   ('name' -> (self argString: 'Name of the new element. Optional.')).
					   ('x' -> (self argNumber: 'Left edge of the new node on the canvas. Optional (next free place).')).
					   ('y' -> (self argNumber: 'Top edge of the new node on the canvas. Optional.')).
					   ('parent' -> (self argString: 'Id of the element to create the node in (e.g. the class of a new attribute). Optional.')) }
			   required: #( 'type' )
			   selector: #createElement:).
		  (self
			   tool: 'connect_elements'
			   description:
			   'Create an edge of the given type (palette label of kind "edge", e.g. "Association", "Generalization", "Regular Connection") from source to target. Answers the new edge.'
			   arguments: {
					   project.
					   diagram.
					   ('type' -> (self argString: 'Palette label of an edge type.')).
					   ('source' -> (self argString: 'Id of the source element.')).
					   ('target' -> (self argString: 'Id of the target element.')).
					   ('name' -> (self argString: 'Name of the edge. Optional.')) }
			   required: #( 'type' 'source' 'target' )
			   selector: #connectElements:).
		  (self
			   tool: 'set_properties'
			   description:
			   'Change properties of an element, e.g. {"name": "Person", "isAbstract": true}. Any property the element''s model has (with a setter) can be set to a string, number, boolean or null. Special properties: "type" (UML attribute or parameter type given by the name of a class, enumeration or primitive type), "multiplicity" (UML attribute, e.g. "0..*", "1", "*", "1...3", real bounds such as "0.5..2.5") and "stereotype" (name of a stereotype of the model''s profile, e.g. OntoUML "Kind", "Role", "Mediation"; null removes it).'
			   arguments: {
					   project.
					   diagram.
					   ('element' -> (self argString: 'Element id.')).
					   ('properties' -> (self argObject: 'Property names and their new values.')) }
			   required: #( 'element' 'properties' )
			   selector: #setProperties:).
		  (self
			   tool: 'move_element'
			   description: 'Move and optionally resize a node.'
			   arguments: {
					   project.
					   diagram.
					   ('element' -> (self argString: 'Element id.')).
					   ('x' -> (self argNumber: 'New left edge.')).
					   ('y' -> (self argNumber: 'New top edge.')).
					   ('width' -> (self argNumber: 'New width. Optional.')).
					   ('height' -> (self argNumber: 'New height. Optional.')) }
			   required: #( 'element' 'x' 'y' )
			   selector: #moveElement:).
		  (self
			   tool: 'delete_elements'
			   description:
			   'Delete elements from the model (like the Delete key): dependent elements such as edges of a deleted node are deleted too.'
			   arguments: {
					   project.
					   diagram.
					   ('elements' -> (self argStrings: 'Ids of the elements to delete.')) }
			   required: #( 'elements' )
			   selector: #deleteElements:).
		  (self
			   tool: 'duplicate_elements'
			   description:
			   'Duplicate elements like Cmd/Ctrl+D: copies with their content (e.g. attributes), edges among them, style and an offset position. Answers the copies.'
			   arguments: {
					   project.
					   diagram.
					   ('elements' -> (self argStrings: 'Ids of the elements to duplicate.')) }
			   required: #( 'elements' )
			   selector: #duplicateElements:).
		  (self
			   tool: 'set_association_end'
			   description:
			   'Change one end of a UML/OntoUML association: role name, multiplicity, aggregation and navigability. The end is chosen by the element it is attached to (its type), as multiplicities are drawn next to that element.'
			   arguments: {
					   project.
					   diagram.
					   ('element' -> (self argString: 'Id of the association.')).
					   ('at' -> (self argString: 'Id of the element at that end, or "source" / "target".')).
					   ('name' -> (self argString: 'Role name. Optional.')).
					   ('multiplicity' -> (self argString: 'E.g. "1", "0..1", "0..*", "1..*", "*", "1...3", "0.5..2.5". Optional.')).
					   ('aggregation' -> (self argString: '"none", "shared" or "composite" (UML: set on the part''s end, the diamond is drawn at the whole). Optional.')).
					   ('navigable' -> (self argBoolean: 'Navigability of the end. Optional.')) }
			   required: #( 'element' 'at' )
			   selector: #setAssociationEnd:).
		  (self
			   tool: 'create_generalization_set'
			   description:
			   'Group generalizations with the same general element into a generalization set, e.g. {disjoint, complete} (DC) or {overlapping, incomplete} (OI).'
			   arguments: {
					   project.
					   diagram.
					   ('generalizations' -> (self argStrings: 'Ids of the generalization edges.')).
					   ('disjoint' -> (self argBoolean: 'Disjoint (true) or overlapping (false).')).
					   ('covering' -> (self argBoolean: 'Complete (true) or incomplete (false).')).
					   ('name' -> (self argString: 'Name of the set. Optional.')) }
			   required: #( 'generalizations' 'disjoint' 'covering' )
			   selector: #createGeneralizationSet:).
		  (self
			   tool: 'auto_layout'
			   description:
			   'Arrange a diagram automatically, as one undoable step. "tidy" (the default) keeps the arrangement and only removes overlaps: pushes apart nodes that overlap or that an edge passes through, and moves edge labels (names, multiplicities, generalization sets) to free places. The other algorithms are the layouters of OpenPonk that place all nodes anew: "default" (the notation''s preferred one), "hierarchical" (Sugiyama), "tree", "dominance", "grid"; follow them with "tidy".'
			   arguments: {
					   project.
					   diagram.
					   ('algorithm' -> (self argString: '"tidy" (default), "default", "hierarchical", "tree", "dominance" or "grid".')) }
			   required: #(  )
			   selector: #autoLayout:).
		  (self
			   tool: 'undo'
			   description: 'Undo the last change in a project (same as Cmd/Ctrl+Z in OpenPonk).'
			   arguments: { project }
			   required: #(  )
			   selector: #undo:).
		  (self
			   tool: 'redo'
			   description: 'Redo the last undone change in a project.'
			   arguments: { project }
			   required: #(  )
			   selector: #redo:).
		  ((self
			    tool: 'export_diagram_png'
			    description: 'Render a diagram to a PNG image to look at it.'
			    arguments: {
					    project.
					    diagram }
			    required: #(  )
			    selector: #exportDiagramPng:)
			   returnsContent: true;
			   yourself) }
]

{ #category : 'calling' }
OPMcpTools >> call: aToolName arguments: aDictionary [
	"Answer the MCP result of tools/call."

	| tool result |
	tool := self definitions
		        detect: [ :each | each name = aToolName ]
		        ifNone: [
			        OPMcpProtocolError
				        signalCode: -32602
				        message: 'Unknown tool: ' , aToolName asString ].
	aDictionary isDictionary ifFalse: [
		OPMcpProtocolError signalCode: -32602 message: 'Arguments must be an object' ].
	result := [ self inUIDo: [ self perform: tool selector with: aDictionary ] ]
		          on: OPMcpToolError
		          do: [ :error | ^ self errorResult: error messageText ].
	^ tool returnsContent
		  ifTrue: [ self contentResult: result ]
		  ifFalse: [ self contentResult: { (self textContent: (NeoJSONWriter toStringPretty: result)) } ]
]

{ #category : 'private' }
OPMcpTools >> completeCreationOf: aController by: aPaletteEntry [
	"What the palette tool does after creating an element (OntoUML entries apply their stereotype here)."

	(aPaletteEntry at: #onComplete) ifNotNil: [ :block | block cull: aController ]
]

{ #category : 'tools' }
OPMcpTools >> autoLayout: arguments [

	| diagramController layouter algorithm selector |
	diagramController := self diagramControllerFor: arguments.
	layouter := diagramController layouter.
	algorithm := ((arguments at: 'algorithm' ifAbsent: [ nil ]) ifNil: [ 'tidy' ]) asString asLowercase.
	algorithm = 'tidy' ifTrue: [
		self inTransactionOf: diagramController labeled: 'MCP: tidy' do: [
			(OPDiagramTidier on: diagramController) tidy ].
		^ self layoutResultOf: diagramController algorithm: algorithm ].
	selector := self layoutAlgorithms at: algorithm ifAbsent: [
		            OPMcpToolError signal: 'Unknown algorithm "' , algorithm , '". Algorithms: '
			            , (', ' join: #( 'tidy' ) , self layoutAlgorithms keys asSortedCollection asArray) ].
	(selector key isNil or: [ layouter supports: (Smalltalk at: selector key) ]) ifFalse: [
		OPMcpToolError signal: 'This diagram does not support the "' , algorithm , '" layout' ].
	self inTransactionOf: diagramController labeled: 'MCP: layout' do: [
		layouter perform: selector value ].
	^ self layoutResultOf: diagramController algorithm: algorithm
]

{ #category : 'private - json' }
OPMcpTools >> layoutResultOf: aDiagramController algorithm: aString [

	aDiagramController canvas signalUpdate.
	^ OrderedDictionary new
		  at: 'algorithm' put: aString;
		  at: 'elements' put: ((aDiagramController controllers select: [ :each |
				    each diagramElement isNotNil and: [ each diagramElement isEdge not ] ])
				   collect: [ :each | self elementJson: each in: aDiagramController ]) asArray;
		  yourself
]

{ #category : 'private' }
OPMcpTools >> change: aDiagramElement bounds: newBounds in: aDiagramController [

	aDiagramController undoManager
		ifNil: [ aDiagramElement bounds: newBounds ]
		ifNotNil: [ :undoManager |
			undoManager execute: (OPChangeBoundsCommand
					 element: aDiagramElement
					 oldBounds: aDiagramElement bounds
					 newBounds: newBounds) ]
]

{ #category : 'private' }
OPMcpTools >> layoutAlgorithms [
	"Algorithm name -> (layout command class name that must be supported, or nil) -> layouter selector."

	^ Dictionary new
		  at: 'default' put: nil -> #defaultLayout;
		  at: 'hierarchical' put: #OPSugiyamaLayoutCommand -> #sugiyamaLayout;
		  at: 'tree' put: #OPTreeLayoutCommand -> #treeLayout;
		  at: 'dominance' put: #OPDominanceTreeLayoutCommand -> #dominanceTreeLayout;
		  at: 'grid' put: #OPGridLayoutCommand -> #gridLayout;
		  yourself
]

{ #category : 'tools' }
OPMcpTools >> connectElements: arguments [

	| diagramController entry source target edge |
	diagramController := self diagramControllerFor: arguments.
	entry := self paletteEntry: (self arguments: arguments at: 'type') in: diagramController.
	(entry at: #kind) = 'edge' ifFalse: [
		OPMcpToolError signal: '"' , (entry at: #label) , '" is not an edge type; use create_element' ].
	source := self controllerIn: diagramController id: (self arguments: arguments at: 'source').
	target := self controllerIn: diagramController id: (self arguments: arguments at: 'target').
	edge := (entry at: #factory) value.
	(source canBeSourceFor: edge) ifFalse: [
		OPMcpToolError signal: (self describe: source) , ' cannot be the source of ' , (entry at: #label) ].
	"Only remembers the source; validity of the target may depend on it (e.g. in ER diagrams)."
	source addAsSourceFor: edge.
	(target canBeTargetFor: edge) ifFalse: [
		OPMcpToolError signal: (self describe: target) , ' cannot be the target of ' , (entry at: #label)
			, ' from ' , (self describe: source) ].
	self inTransactionOf: diagramController labeled: 'MCP: connect' do: [
		target addAsTargetFor: edge.
		self completeCreationOf: edge by: entry.
		(arguments at: 'name' ifAbsent: [ nil ]) ifNotNil: [ :name |
			self rename: edge to: name ] ].
	diagramController canvas signalUpdate.
	^ self elementJson: edge in: diagramController
]

{ #category : 'private - results' }
OPMcpTools >> contentResult: aCollectionOfContent [

	^ OrderedDictionary new
		  at: 'content' put: aCollectionOfContent asArray;
		  at: 'isError' put: false;
		  yourself
]

{ #category : 'private - resolving' }
OPMcpTools >> controllerIn: aDiagramController id: anId [

	| byName |
	aDiagramController controllers
		detect: [ :each | (self idOf: each) = anId asString ]
		ifFound: [ :found | ^ found ].
	byName := aDiagramController controllers select: [ :each |
		          (self nameOf: each model) = anId ].
	byName size = 1 ifTrue: [ ^ byName anyOne ].
	OPMcpToolError signal: 'No element with id "' , anId asString
		, '" in the diagram (use get_diagram for ids)'
]

{ #category : 'tools' }
OPMcpTools >> createElement: arguments [

	| diagramController entry controller parent position |
	diagramController := self diagramControllerFor: arguments.
	entry := self paletteEntry: (self arguments: arguments at: 'type') in: diagramController.
	(entry at: #kind) = 'node' ifFalse: [
		OPMcpToolError signal: '"' , (entry at: #label) , '" is an edge type; use connect_elements' ].
	controller := (entry at: #factory) value.
	parent := (arguments at: 'parent' ifAbsent: [ nil ])
		          ifNil: [ diagramController ]
		          ifNotNil: [ :id | self controllerIn: diagramController id: id ].
	(parent canBeTargetFor: controller) ifFalse: [
		OPMcpToolError signal: (parent == diagramController
				 ifTrue: [ '"' , (entry at: #label) , '" must be created inside a parent element (pass "parent")' ]
				 ifFalse: [ '"' , (entry at: #label) , '" cannot be created inside ' , (self describe: parent) ]) ].
	position := self positionFrom: arguments in: diagramController parent: parent.
	self inTransactionOf: diagramController labeled: 'MCP: create ' , (entry at: #label) do: [
		parent addAsTargetFor: controller onPosition: position.
		position ifNotNil: [ self placeTopLeftOf: controller diagramElement at: position ].
		self completeCreationOf: controller by: entry.
		(arguments at: 'name' ifAbsent: [ nil ]) ifNotNil: [ :name |
			self rename: controller to: name ] ].
	diagramController canvas signalUpdate.
	^ self elementJson: controller in: diagramController
]

{ #category : 'tools' }
OPMcpTools >> createProject: arguments [

	| name plugin model project |
	name := (self arguments: arguments at: 'name') asString.
	plugin := self pluginNamed: (self arguments: arguments at: 'notation') asString.
	"The empty-model template, as the project browser of OpenPonk does."
	model := (plugin defaultProjectTemplates
		          detect: [ :each | each isExample not ]
		          ifNone: [ nil ])
		         ifNil: [ plugin newModel ]
		         ifNotNil: [ :template | template createModel ].
	(model respondsTo: #name:) ifTrue: [ model name: name ].
	project := OPProject new
		           name: name;
		           addModel: model;
		           yourself.
	^ self projectJson: project open
]

{ #category : 'definitions' }
OPMcpTools >> definitions [

	^ definitions ifNil: [ definitions := self buildDefinitions ]
]

{ #category : 'tools' }
OPMcpTools >> deleteElements: arguments [

	| diagramController controllers deleted |
	diagramController := self diagramControllerFor: arguments.
	controllers := (self arguments: arguments stringsAt: 'elements') collect: [ :each |
		               self controllerIn: diagramController id: each ].
	deleted := controllers collect: [ :each | self idOf: each ].
	self inTransactionOf: diagramController labeled: 'MCP: delete' do: [
		controllers do: [ :each |
			(diagramController hasControllerForModel: each model) ifTrue: [
				diagramController removeModelOfRoassalShape: each roassalShape ] ] ].
	diagramController canvas signalUpdate.
	^ Dictionary new
		  at: 'deleted' put: deleted asArray;
		  yourself
]

{ #category : 'private - json' }
OPMcpTools >> describe: aController [

	^ (self typeNameOf: aController) , ' "' , ((self nameOf: aController model) ifNil: [ self idOf: aController ]) , '"'
]

{ #category : 'private - resolving' }
OPMcpTools >> diagramControllerFor: arguments [
	"Open (or focus) the editor of the requested diagram and answer its controller."

	| workbench diagram |
	workbench := self workbenchFor: arguments.
	diagram := self diagramIn: workbench arguments: arguments.
	workbench openEditorOnDiagram: diagram.
	^ workbench projectController controllers
		  detect: [ :each | each diagramElement == diagram ]
		  ifNone: [ OPMcpToolError signal: 'Could not open the diagram editor' ]
]

{ #category : 'private - resolving' }
OPMcpTools >> diagramIn: aWorkbench arguments: arguments [

	| diagrams key |
	diagrams := aWorkbench project diagrams asArray.
	diagrams ifEmpty: [ OPMcpToolError signal: 'The project has no diagram' ].
	key := arguments at: 'diagram' ifAbsent: [ nil ].
	key ifNil: [
		aWorkbench focusedEditor ifNotNil: [ :editor |
			(diagrams includes: editor diagramController diagramElement) ifTrue: [
				^ editor diagramController diagramElement ] ].
		^ diagrams first ].
	(key isNumber or: [ key isString and: [ key notEmpty and: [ key isAllDigits ] ] ])
		ifTrue: [
			^ diagrams at: key asString asNumber ifAbsent: [
				  OPMcpToolError signal: 'The project has ' , diagrams size printString , ' diagram(s)' ] ].
	^ diagrams
		  detect: [ :each | each name = key ]
		  ifNone: [
			  OPMcpToolError signal: 'No diagram "' , key asString , '" in project "'
				  , aWorkbench project name , '"' ]
]

{ #category : 'private - json' }
OPMcpTools >> diagramJson: aDiagram index: anInteger in: aWorkbench [

	^ OrderedDictionary new
		  at: 'index' put: anInteger;
		  at: 'name' put: aDiagram name;
		  at: 'model' put: (self nameOf: aDiagram modelElement);
		  at: 'notation' put: ([ (aWorkbench pluginRegistry pluginFor: aDiagram modelElement) name ]
				   on: Error
				   do: [ nil ]);
		  at: 'open' put: (aWorkbench projectController hasDiagram: aDiagram);
		  yourself
]

{ #category : 'tools' }
OPMcpTools >> duplicateElements: arguments [

	| diagramController controllers copies |
	diagramController := self diagramControllerFor: arguments.
	controllers := (self arguments: arguments stringsAt: 'elements') collect: [ :each |
		               self controllerIn: diagramController id: each ].
	copies := (OPDiagramElementsDuplicator on: diagramController) duplicateControllers: controllers.
	diagramController canvas signalUpdate.
	^ Dictionary new
		  at: 'copies' put: (copies collect: [ :each | self elementJson: each in: diagramController ]) asArray;
		  yourself
]

{ #category : 'private - json' }
OPMcpTools >> elementJson: aController in: aDiagramController [

	| json element owner |
	json := OrderedDictionary new.
	element := aController diagramElement.
	json
		at: 'id' put: (self idOf: aController);
		at: 'type' put: (self typeNameOf: aController);
		at: 'name' put: (self nameOf: aController model).
	([ aController viewModel modelDisplayString ]
		 on: Error
		 do: [ nil ]) ifNotNil: [ :label |
		(label isEmpty or: [ label = (json at: 'name') ]) ifFalse: [ json at: 'label' put: label ] ].
	element isEdge
		ifTrue: [
			json
				at: 'kind' put: 'edge';
				at: 'source' put: (self idOfDiagramElement: element source in: aDiagramController);
				at: 'target' put: (self idOfDiagramElement: element target in: aDiagramController) ]
		ifFalse: [
			json at: 'kind' put: 'node'.
			element isPositionableByUser ifTrue: [ self boundsOf: element into: json ] ].
	owner := element owningElementWithPossibleController.
	(owner isNotNil and: [ owner ~~ aDiagramController diagramElement ]) ifTrue: [
		json at: 'parent' put: (self idOfDiagramElement: owner in: aDiagramController) ].
	(self propertiesOf: aController model) ifNotEmpty: [ :properties |
		json at: 'properties' put: properties ].
	^ json
]

{ #category : 'private - results' }
OPMcpTools >> errorResult: aString [

	^ OrderedDictionary new
		  at: 'content' put: { (self textContent: aString) };
		  at: 'isError' put: true;
		  yourself
]

{ #category : 'tools' }
OPMcpTools >> exportDiagramPng: arguments [

	| diagramController file bytes |
	diagramController := self diagramControllerFor: arguments.
	file := FileLocator temp / ('openponk-mcp-' , UUID new asString , '.png').
	[
	self withWholeDiagramMorphOf: diagramController do: [
		OPCanvasPNGExporter exportSilentlyDiagramController: diagramController to: file ].
	bytes := file binaryReadStream contents ] ensure: [ file ensureDelete ].
	^ {
		  (OrderedDictionary new
			   at: 'type' put: 'image';
			   at: 'data' put: bytes base64Encoded;
			   at: 'mimeType' put: 'image/png';
			   yourself).
		  (self textContent: 'Diagram "' , diagramController diagramElement name , '"') }
]

{ #category : 'tools' }
OPMcpTools >> getDiagram: arguments [

	| diagramController workbench diagram elements |
	diagramController := self diagramControllerFor: arguments.
	workbench := self workbenchFor: arguments.
	diagram := diagramController diagramElement.
	elements := (diagramController controllers select: [ :each |
		             each diagramElement isNotNil ]) asArray.
	elements := (elements reject: [ :each | each diagramElement isEdge ])
	            , (elements select: [ :each | each diagramElement isEdge ]).
	^ OrderedDictionary new
		  at: 'project' put: workbench project name;
		  at: 'diagram' put: (self
				   diagramJson: diagram
				   index: (workbench project diagrams asArray indexOf: diagram)
				   in: workbench);
		  at: 'elements' put: (elements collect: [ :each |
				   self elementJson: each in: diagramController ]);
		  yourself
]

{ #category : 'private - json' }
OPMcpTools >> idOf: aController [

	| model |
	model := aController model.
	((model respondsTo: #uuid) and: [ model uuid isNotNil ]) ifTrue: [
		^ model uuid asString ].
	^ 'element-' , aController diagramElement identityHash printString
]

{ #category : 'private - json' }
OPMcpTools >> idOfDiagramElement: aDiagramElement in: aDiagramController [

	aDiagramElement ifNil: [ ^ nil ].
	^ (aDiagramController
		   controllerForModel: aDiagramElement modelElement
		   ifNone: [ nil ]) ifNotNil: [ :controller | self idOf: controller ]
]

{ #category : 'private' }
OPMcpTools >> inTransactionOf: aDiagramController labeled: aString do: aBlock [

	aDiagramController undoManager
		ifNil: [ aBlock value ]
		ifNotNil: [ :undoManager |
		undoManager inTransactionLabeled: aString do: aBlock ]
]

{ #category : 'private' }
OPMcpTools >> inUIDo: aBlock [
	"Run aBlock in the Morphic UI process and wait for it. Errors are caught there (no debugger pops up in the user's OpenPonk) and re-signalled here."

	| uiProcess semaphore result error |
	uiProcess := UIManager default uiProcess.
	(uiProcess isNil or: [ uiProcess == Processor activeProcess ]) ifTrue: [
		^ [ aBlock value ]
			  on: Error
			  do: [ :each | self signalAsToolError: each ] ].
	semaphore := Semaphore new.
	UIManager default defer: [
		[ result := aBlock value ]
			on: Error
			do: [ :each | error := each ].
		semaphore signal ].
	(semaphore waitTimeoutMilliseconds: self timeoutMilliseconds) ifTrue: [
		OPMcpToolError signal:
			'OpenPonk did not answer in time (is a dialog open in the application?)' ].
	error ifNotNil: [ self signalAsToolError: error ].
	^ result
]

{ #category : 'tools' }
OPMcpTools >> listElementTypes: arguments [

	| diagramController |
	diagramController := self diagramControllerFor: arguments.
	^ OrderedDictionary new
		  at: 'diagram' put: diagramController diagramElement name;
		  at: 'types' put: ((self paletteEntriesOf: diagramController) collect: [ :each |
				   | json |
				   json := OrderedDictionary new
					           at: 'type' put: (each at: #label);
					           at: 'kind' put: (each at: #kind);
					           yourself.
				   (each at: #kind) = 'node' ifTrue: [
					   json at: 'topLevel' put: ([ diagramController canBeTargetFor: (each at: #factory) value ]
							    on: Error
							    do: [ false ]) ].
				   json ]) asArray;
		  yourself
]

{ #category : 'tools' }
OPMcpTools >> listNotations: arguments [

	^ (OPPluginRegistry default plugins collect: [ :each | each name ]) asArray
]

{ #category : 'tools' }
OPMcpTools >> listProjects: arguments [

	^ (self openWorkbenches collect: [ :each | self projectJson: each ]) asArray
]

{ #category : 'tools' }
OPMcpTools >> moveElement: arguments [

	| diagramController controller element oldBounds extent newBounds |
	diagramController := self diagramControllerFor: arguments.
	controller := self controllerIn: diagramController id: (self arguments: arguments at: 'element').
	element := controller diagramElement.
	(element isEdge or: [ element isPositionableByUser not or: [ element bounds isNil ] ])
		ifTrue: [ OPMcpToolError signal: (self describe: controller) , ' cannot be moved' ].
	oldBounds := element bounds.
	extent := ((self arguments: arguments numberAt: 'width') ifNil: [ oldBounds extent x ])
	          @ ((self arguments: arguments numberAt: 'height') ifNil: [ oldBounds extent y ]).
	newBounds := self
		             boundsOf: element
		             withTopLeft: (self arguments: arguments numberAt: 'x')
			             @ (self arguments: arguments numberAt: 'y')
		             extent: extent.
	self inTransactionOf: diagramController labeled: 'MCP: move' do: [
		self change: element bounds: newBounds in: diagramController.
		element updateRenderFromSelf.
		"Shapes that size themselves to their content end up elsewhere than the requested box."
		(self
			 topLeftCorrectionOf: element
			 to: (self arguments: arguments numberAt: 'x') @ (self arguments: arguments numberAt: 'y'))
			ifNotNil: [ :delta |
				delta = (0 @ 0) ifFalse: [
					self
						change: element
						bounds: (OPNodeBounds
								 withPosition: element bounds position + delta
								 extent: element bounds extent)
						in: diagramController ] ] ].
	diagramController canvas signalUpdate.
	^ self elementJson: controller in: diagramController
]

{ #category : 'private - json' }
OPMcpTools >> nameOf: aModel [

	| name |
	(aModel respondsTo: #name) ifFalse: [ ^ nil ].
	name := [ aModel name ]
		        on: Error
		        do: [ nil ].
	^ name ifNotNil: [ name asString ]
]

{ #category : 'tools' }
OPMcpTools >> openProject: arguments [

	| file |
	file := (self arguments: arguments at: 'path') asString asFileReference.
	file exists ifFalse: [ OPMcpToolError signal: 'File not found: ' , file fullName ].
	^ self projectJson: (OPProjectController fromFile: file) open
]

{ #category : 'private - resolving' }
OPMcpTools >> openWorkbenches [

	^ (OPWorkbench allInstances select: [ :each |
		   each window isNotNil and: [
			   each window isOpen and: [ each projectController isNotNil ] ] ])
		  asArray
]

{ #category : 'private - resolving' }
OPMcpTools >> paletteEntriesOf: aDiagramController [
	"Creation entries of the diagram's palette as dictionaries with #label, #kind, #factory and #onComplete (run after creation, e.g. applies the stereotype of OntoUML entries). The tool of some entries is only referenced from their button action, so look there too."

	| palette |
	palette := aDiagramController editor ifNotNil: [ :editor | editor palette ].
	palette ifNil: [ OPMcpToolError signal: 'The diagram has no palette' ].
	^ palette entries
		  collect: [ :each | self paletteEntryOf: each ]
		  thenSelect: [ :each | each isNotNil ]
]

{ #category : 'private - resolving' }
OPMcpTools >> paletteEntry: aLabel in: aDiagramController [

	| entries |
	entries := self paletteEntriesOf: aDiagramController.
	^ entries
		  detect: [ :each | (each at: #label) asLowercase = aLabel asString asLowercase ]
		  ifNone: [
			  OPMcpToolError signal: 'Unknown element type "' , aLabel asString , '". Types: '
				  , (', ' join: (entries collect: [ :each | each at: #label ])) ]
]

{ #category : 'private - resolving' }
OPMcpTools >> paletteEntryOf: anEntry [

	| tool action kind |
	tool := anEntry tool.
	(tool isNil and: [ (action := anEntry action) isNotNil ]) ifTrue: [
		tool := ((1 to: action basicSize) collect: [ :index | action basicAt: index ])
			        detect: [ :each |
				        (each isKindOf: OPCreationTool) or: [
					        each isKindOf: OPConnectionCreationTool ] ]
			        ifNone: [ nil ] ].
	(tool isKindOf: OPCreationTool) ifTrue: [ kind := 'node' ].
	(tool isKindOf: OPConnectionCreationTool) ifTrue: [ kind := 'edge' ].
	(kind isNil or: [ anEntry label isEmptyOrNil ]) ifTrue: [ ^ nil ].
	^ Dictionary new
		  at: #label put: anEntry label asString;
		  at: #kind put: kind;
		  at: #factory put: (tool instVarNamed: #factory);
		  at: #onComplete put: (tool instVarNamed: #onComplete);
		  yourself
]

{ #category : 'private' }
OPMcpTools >> withWholeDiagramMorphOf: aDiagramController do: aBlock [
	"The PNG exporter resizes the canvas morph to the whole diagram, but the morph sits in the editor's layout, which keeps its width, and it recreates its drawing surface only while drawing, which resizes the canvas and lets OpenPonk move the camera the exporter has just set; the image then shows only part of the diagram. So keep the morph out of the layout's sizing, give it the exported extent (as OPRSCustomScaleCamSetter computes it for scale 1) and its surface beforehand, and give it back to the layout afterwards."

	| canvas morph hResizing vResizing |
	canvas := aDiagramController canvas.
	morph := canvas morph ifNil: [ ^ aBlock value ].
	hResizing := morph hResizing.
	vResizing := morph vResizing.
	^ [
	  morph
		  hResizing: #rigid;
		  vResizing: #rigid;
		  extent: canvas encompassingRectangle extent + 25.
	  morph checkSession.
	  morph recreateSurfaceIfNecessary: 1.
	  aBlock value ] ensure: [
		  morph
			  hResizing: hResizing;
			  vResizing: vResizing.
		  morph owner ifNotNil: [ :owner | owner layoutChanged ] ]
]

{ #category : 'private - resolving' }
OPMcpTools >> pluginNamed: aString [

	| plugins exact partial |
	plugins := OPPluginRegistry default plugins.
	exact := plugins select: [ :each | each name asLowercase = aString asLowercase ].
	exact size = 1 ifTrue: [ ^ exact anyOne ].
	partial := plugins select: [ :each |
		           each name asLowercase includesSubstring: aString asLowercase ].
	partial size = 1 ifTrue: [ ^ partial anyOne ].
	OPMcpToolError signal: 'Unknown notation "' , aString , '". Notations: '
		, (', ' join: (plugins collect: [ :each | each name ]))
]

{ #category : 'private' }
OPMcpTools >> positionFrom: arguments in: aDiagramController parent: aParentController [
	"Nodes laid out by their parent (attributes...) get no position; top-level nodes go to the given place or right of the others."

	| x y right |
	aParentController == aDiagramController ifFalse: [ ^ nil ].
	x := self arguments: arguments numberAt: 'x'.
	y := self arguments: arguments numberAt: 'y'.
	(x isNotNil and: [ y isNotNil ]) ifTrue: [ ^ x @ y ].
	right := 0.
	aDiagramController controllers do: [ :each |
		| element |
		element := each diagramElement.
		(element isNotNil and: [
			 element isEdge not and: [
				 element owningElement == aDiagramController diagramElement and: [
					 element bounds isNotNil ] ] ]) ifTrue: [
			right := right max: (self displayedRectangleOf: element) right ] ].
	^ (x ifNil: [ right + 60 ]) @ (y ifNil: [ 60 ])
]

{ #category : 'private - json' }
OPMcpTools >> projectJson: aWorkbench [

	| project diagrams |
	project := aWorkbench project.
	diagrams := project diagrams asArray.
	^ OrderedDictionary new
		  at: 'name' put: project name;
		  at: 'id' put: project uuid asString;
		  at: 'file' put: ((aWorkbench projectController recentProjects
				    at: project uuid
				    ifAbsent: [ nil ]) ifNotNil: [ :file | file asFileReference fullName ]);
		  at: 'diagrams' put: (diagrams withIndexCollect: [ :each :index |
				   self diagramJson: each index: index in: aWorkbench ]);
		  yourself
]

{ #category : 'private - json' }
OPMcpTools >> plainPropertiesOf: aModel into: aDictionary [
	"Simple values of non-UML models, e.g. isWeak of an ER entity or isKey of an attribute."

	aModel class allInstVarNames do: [ :each |
		| value |
		(#( #name #uuid #owner #elements #announcer ) includes: each asSymbol) ifFalse: [
			value := aModel instVarNamed: each.
			(value == true or: [
				 value == false or: [
					 value isNumber or: [ value isString and: [ value isEmpty not ] ] ] ])
				ifTrue: [ aDictionary at: each asString put: value ] ] ]
]

{ #category : 'private - json' }
OPMcpTools >> propertiesOf: aModel [

	| properties |
	properties := OrderedDictionary new.
	aModel ifNil: [ ^ properties ].
	[
	(aModel isKindOf: OPUMLMetaElement)
		ifTrue: [ self umlPropertiesOf: aModel into: properties ]
		ifFalse: [ self plainPropertiesOf: aModel into: properties ] ]
		on: Error
		do: [ "best effort, never fail a listing" ].
	^ properties
]

{ #category : 'tools' }
OPMcpTools >> redo: arguments [

	| undoManager |
	undoManager := (self workbenchFor: arguments) projectController undoManager.
	undoManager canRedo ifFalse: [ OPMcpToolError signal: 'Nothing to redo' ].
	undoManager redo.
	^ Dictionary new
		  at: 'redone' put: true;
		  yourself
]

{ #category : 'private' }
OPMcpTools >> rename: aController to: aName [

	(aController model respondsTo: #name:) ifFalse: [
		OPMcpToolError signal: (self describe: aController) , ' has no name' ].
	aController model name: aName asString.
	aController viewModel ifNotNil: [ :viewModel | viewModel modelChanged ].
	aController diagramElement ifNotNil: [ :element |
		element isRendered ifTrue: [ aController modelChanged ] ]
]

{ #category : 'tools' }
OPMcpTools >> saveProject: arguments [

	| workbench file |
	workbench := self workbenchFor: arguments.
	file := (arguments at: 'path' ifAbsent: [ nil ])
		        ifNil: [
			        workbench projectController recentProjects
				        at: workbench project uuid
				        ifAbsent: [
					        OPMcpToolError signal:
						        'The project was never saved; pass "path" (absolute path of a .opp file)' ] ]
		        ifNotNil: [ :path | path asString asFileReference ].
	file := file asFileReference.
	file parent exists ifFalse: [
		OPMcpToolError signal: 'Directory does not exist: ' , file parent fullName ].
	workbench projectController saveProjectTo: file.
	^ Dictionary new
		  at: 'saved' put: file fullName;
		  yourself
]

{ #category : 'tools' }
OPMcpTools >> setProperties: arguments [

	| diagramController controller properties |
	diagramController := self diagramControllerFor: arguments.
	controller := self controllerIn: diagramController id: (self arguments: arguments at: 'element').
	properties := self arguments: arguments at: 'properties'.
	properties isDictionary ifFalse: [
		OPMcpToolError signal: '"properties" must be an object' ].
	self inTransactionOf: diagramController labeled: 'MCP: set properties' do: [
		properties keysAndValuesDo: [ :key :value |
			self setProperty: key asString to: value of: controller ] ].
	controller viewModel ifNotNil: [ :viewModel | viewModel modelChanged ].
	controller modelChanged.
	diagramController canvas signalUpdate.
	^ self elementJson: controller in: diagramController
]

{ #category : 'private' }
OPMcpTools >> setProperty: aName to: aValue of: aController [

	| model viewModel newValue command |
	model := aController model.
	viewModel := aController viewModel.
	aName = 'multiplicity' ifTrue: [
		^ self setMultiplicity: aValue of: aController ].
	aName = 'stereotype' ifTrue: [ ^ self setStereotype: aValue of: aController ].
	((model respondsTo: aName asSymbol) and: [ model respondsTo: aName asSymbol asMutator ])
		ifFalse: [ OPMcpToolError signal: (self describe: aController) , ' has no property "' , aName , '"' ].
	newValue := aValue.
	(aName = 'type' and: [ aValue isString and: [ viewModel respondsTo: #typeNamed: ] ]) ifTrue: [
		newValue := (viewModel typeNamed: aValue) ifNil: [
			            OPMcpToolError signal: 'No type named "' , aValue , '"' ] ].
	(newValue isNil or: [
		 newValue isString or: [
			 newValue isNumber or: [ newValue == true or: [ newValue == false or: [ aName = 'type' ] ] ] ] ])
		ifFalse: [ OPMcpToolError signal: 'Value of "' , aName , '" must be a string, number, boolean or null' ].
	command := OPPropertyChangeCommand
		           viewModel: viewModel
		           selector: aName asSymbol
		           oldValue: (model perform: aName asSymbol)
		           newValue: newValue.
	aController undoManager
		ifNil: [ command execute ]
		ifNotNil: [ :undoManager | undoManager execute: command ]
]

{ #category : 'private' }
OPMcpTools >> setMultiplicity: aValue of: aController [
	"UML multiplicity given as text, e.g. '0..*', '1', '*'; undoable through a property change with an accessor, as the properties form does."

	| viewModel model accessor command |
	viewModel := aController viewModel.
	model := aController model.
	(viewModel respondsTo: #writeMultiplicityFrom:to:) ifFalse: [
		OPMcpToolError signal: (self describe: aController) , ' has no multiplicity' ].
	"Validate here: the view model only informs the user about invalid text."
	self multiplicityBoundsFrom: aValue asString.
	accessor := MAPluggableAccessor
		            read: [ :aViewModel | self multiplicityOf: model ]
		            write: [ :aViewModel :aString |
		            aViewModel writeMultiplicityFrom: aString to: model ].
	command := OPPropertyChangeCommand
		           viewModel: viewModel
		           selector: #multiplicity
		           accessor: accessor
		           oldValue: (self multiplicityOf: model)
		           newValue: aValue asString.
	aController undoManager
		ifNil: [ command execute ]
		ifNotNil: [ :undoManager | undoManager execute: command ]
]

{ #category : 'private' }
OPMcpTools >> multiplicityOf: aProperty [

	| lower upper |
	lower := aProperty lowerValue ifNotNil: [ :spec | spec value ].
	upper := aProperty upperValue ifNotNil: [ :spec | spec value ].
	(lower isNil and: [ upper isNil ]) ifTrue: [ ^ '1' ].
	lower = upper ifTrue: [ ^ lower asString ].
	^ (lower ifNil: [ 0 ]) asString , '..' , (upper ifNil: [ '*' ]) asString
]

{ #category : 'private' }
OPMcpTools >> setStereotype: aNameOrNil of: aController [
	"Apply the stereotype of the given name from the profiles applied to the diagram's model (e.g. OntoUML 'Kind', 'Role', 'Mediation'), replacing the current one; nil removes it. Undoable."

	| model viewModel previous stereotype command |
	model := aController model.
	viewModel := aController viewModel.
	((model respondsTo: #appliedStereotypes) and: [ viewModel respondsTo: #applyStereotype:to: ])
		ifFalse: [ OPMcpToolError signal: (self describe: aController) , ' cannot have stereotypes' ].
	stereotype := aNameOrNil ifNotNil: [
		              self stereotypeNamed: aNameOrNil asString for: aController ].
	previous := model appliedStereotypes copy.
	command := OPMcpBlockCommand
		           named: 'Change stereotype'
		           execute: [
			           stereotype
				           ifNil: [ viewModel removeStereotypesIn: model ]
				           ifNotNil: [ viewModel applyStereotype: stereotype to: model ] ]
		           undo: [
			           viewModel removeStereotypesIn: model.
			           previous do: [ :each | model applyStereotype: each ] ].
	aController undoManager
		ifNil: [ command execute ]
		ifNotNil: [ :undoManager | undoManager execute: command ]
]

{ #category : 'private' }
OPMcpTools >> signalAsToolError: anError [

	(anError isKindOf: OPMcpToolError) ifTrue: [
		OPMcpToolError signal: anError messageText ].
	OPMcpToolError signal: anError class name , ': ' , anError messageText asString
]

{ #category : 'private - resolving' }
OPMcpTools >> stereotypeNamed: aString for: aController [

	| root stereotypes |
	root := aController diagramController model.
	stereotypes := (root respondsTo: #profileApplications)
		               ifTrue: [
			               root profileApplications flatCollect: [ :each |
				               each appliedProfile ownedStereotype reject: [ :stereotype |
					               stereotype isAbstract ] ] ]
		               ifFalse: [ #(  ) ].
	^ stereotypes
		  detect: [ :each | each name asLowercase = aString asLowercase ]
		  ifNone: [
			  OPMcpToolError signal: (stereotypes
					   ifEmpty: [ 'The model has no profile with stereotypes' ]
					   ifNotEmpty: [
						   'Unknown stereotype "' , aString , '". Stereotypes: '
						   , (', ' join: (stereotypes collect: [ :each | each name ])) ]) ]
]

{ #category : 'private - results' }
OPMcpTools >> textContent: aString [

	^ OrderedDictionary new
		  at: 'type' put: 'text';
		  at: 'text' put: aString;
		  yourself
]

{ #category : 'private' }
OPMcpTools >> timeoutMilliseconds [

	^ 30000
]

{ #category : 'definitions' }
OPMcpTools >> tool: aName description: aDescription arguments: aCollectionOfAssociations required: requiredNames selector: aSelector [

	| properties schema |
	properties := OrderedDictionary new.
	aCollectionOfAssociations do: [ :each | properties at: each key put: each value ].
	schema := OrderedDictionary new
		          at: 'type' put: 'object';
		          at: 'properties' put: properties;
		          yourself.
	requiredNames ifNotEmpty: [ schema at: 'required' put: requiredNames asArray ].
	^ OPMcpTool new
		  name: aName;
		  description: aDescription;
		  inputSchema: schema;
		  selector: aSelector;
		  yourself
]

{ #category : 'private - json' }
OPMcpTools >> typeNameOf: aController [

	^ [ aController viewModel nameOfType asString ]
		  on: Error
		  do: [ aController model class name asString ]
]

{ #category : 'private - json' }
OPMcpTools >> umlEndJson: aProperty [

	| json |
	json := OrderedDictionary new.
	json at: 'name' put: (self nameOf: aProperty).
	self umlPropertiesOf: aProperty into: json.
	json at: 'navigable' put: aProperty isNavigable.
	^ json
]

{ #category : 'private - json' }
OPMcpTools >> umlPropertiesOf: aModel into: aDictionary [

	((aModel respondsTo: #type) and: [ aModel type isNotNil ]) ifTrue: [
		aDictionary at: 'type' put: (self nameOf: aModel type) ].
	((aModel respondsTo: #lowerValue) and: [
		 aModel lowerValue isNotNil or: [ aModel upperValue isNotNil ] ]) ifTrue: [
		aDictionary at: 'multiplicity' put: (self multiplicityOf: aModel) ].
	((aModel respondsTo: #visibility) and: [
		 aModel visibility isNotNil and: [ aModel visibility ~= #public ] ]) ifTrue: [
		aDictionary at: 'visibility' put: aModel visibility asString ].
	#( #isAbstract #isStatic #isDerived #isReadOnly ) do: [ :each |
		((aModel respondsTo: each) and: [ (aModel perform: each) == true ]) ifTrue: [
			aDictionary at: each asString put: true ] ].
	((aModel respondsTo: #aggregation) and: [
		 aModel aggregation isNotNil and: [ aModel aggregation ~= #none ] ]) ifTrue: [
		aDictionary at: 'aggregation' put: aModel aggregation asString ].
	aModel appliedStereotypes ifNotEmpty: [ :stereotypes |
		aDictionary at: 'stereotypes' put: (stereotypes collect: [ :each |
				 [ each umlClassName ]
					 on: Error
					 do: [ each class name ] ]) asArray ].
	(aModel isKindOf: OPUMLAssociation) ifTrue: [
		aDictionary at: 'ends' put: (aModel memberEnds collect: [ :each |
				 self umlEndJson: each ]) asArray ].
	((aModel isKindOf: OPUMLGeneralization) and: [ aModel generalizationSets notEmpty ]) ifTrue: [
		aDictionary at: 'generalizationSets' put: (aModel generalizationSets collect: [ :each |
				 OrderedDictionary new
					 at: 'id' put: each uuid asString;
					 at: 'name' put: each name;
					 at: 'disjoint' put: each isDisjoint == true;
					 at: 'covering' put: each isCovering == true;
					 yourself ]) asArray ]
]

{ #category : 'tools' }
OPMcpTools >> createGeneralizationSet: arguments [

	| diagramController generalizations generals package set command |
	diagramController := self diagramControllerFor: arguments.
	generalizations := (self arguments: arguments stringsAt: 'generalizations') collect: [ :each |
		                   (self controllerIn: diagramController id: each) model ].
	(generalizations allSatisfy: [ :each | each isKindOf: OPUMLGeneralization ]) ifFalse: [
		OPMcpToolError signal: 'All elements must be generalizations' ].
	generals := (generalizations collect: [ :each | each general ]) asSet.
	generals size = 1 ifFalse: [
		OPMcpToolError signal: 'The generalizations must have the same general element' ].
	package := diagramController model.
	(package respondsTo: #packagedElements) ifFalse: [
		OPMcpToolError signal: 'The diagram has no package to own the set' ].
	set := OPUMLGeneralizationSet new.
	set
		name: ((arguments at: 'name' ifAbsent: [ nil ]) ifNotNil: [ :name | name asString ]);
		isDisjoint: (self arguments: arguments at: 'disjoint') == true;
		isCovering: (self arguments: arguments at: 'covering') == true.
	command := OPUmlUpdateGeneralizationSetsCommand new.
	command
		viewModelRegistry: diagramController viewModelRegistry;
		affectedGeneralizations: generalizations;
		recordAddSet: set toPackage: package;
		recordMembershipChangeOn: set added: generalizations asArray removed: #(  ).
	self inTransactionOf: diagramController labeled: 'MCP: generalization set' do: [
		diagramController undoManager
			ifNil: [ command execute ]
			ifNotNil: [ :undoManager | undoManager execute: command ] ].
	diagramController canvas signalUpdate.
	^ self generalizationSetJson: set in: diagramController
]

{ #category : 'private - json' }
OPMcpTools >> generalizationSetJson: aSet in: aDiagramController [

	^ OrderedDictionary new
		  at: 'id' put: aSet uuid asString;
		  at: 'name' put: aSet name;
		  at: 'disjoint' put: aSet isDisjoint == true;
		  at: 'covering' put: aSet isCovering == true;
		  at: 'generalizations' put: (aSet generalizations
				   collect: [ :each |
					   (aDiagramController controllerForModel: each ifNone: [ nil ])
						   ifNotNil: [ :controller | self idOf: controller ] ]
				   thenSelect: [ :each | each isNotNil ]) asArray;
		  yourself
]

{ #category : 'private' }
OPMcpTools >> multiplicityBoundsFrom: aString [
	"Answer { lower. upper } (upper '*' when unlimited), see OPMultiplicityParser."

	^ [ OPMultiplicityParser boundsFrom: aString ]
		  on: OPInvalidMultiplicity
		  do: [ :error | OPMcpToolError signal: error messageText ]
]

{ #category : 'tools' }
OPMcpTools >> setAssociationEnd: arguments [

	| diagramController controller end oldState newState bounds command |
	diagramController := self diagramControllerFor: arguments.
	controller := self controllerIn: diagramController id: (self arguments: arguments at: 'element').
	(controller model isKindOf: OPUMLAssociation) ifFalse: [
		OPMcpToolError signal: (self describe: controller) , ' is not an association' ].
	end := self
		       endOf: controller
		       at: (self arguments: arguments at: 'at') asString
		       in: diagramController.
	oldState := { end name. end lowerValue. end upperValue. end aggregation }.
	newState := oldState copy.
	(arguments includesKey: 'name') ifTrue: [
		newState at: 1 put: ((arguments at: 'name') ifNotNil: [ :name | name asString ]) ].
	(arguments at: 'multiplicity' ifAbsent: [ nil ]) ifNotNil: [ :text |
		bounds := self multiplicityBoundsFrom: text.
		newState
			at: 2 put: (OPUMLLiteralInteger new value: bounds first; yourself);
			at: 3 put: (OPUMLLiteralUnlimitedNatural new value: bounds second; yourself) ].
	(arguments at: 'aggregation' ifAbsent: [ nil ]) ifNotNil: [ :kind |
		(#( 'none' 'shared' 'composite' ) includes: kind asString) ifFalse: [
			OPMcpToolError signal: 'Aggregation must be "none", "shared" or "composite"' ].
		newState at: 4 put: kind asString asSymbol ].
	command := OPMcpBlockCommand
		           named: 'Change association end'
		           execute: [ self setEnd: end to: newState ]
		           undo: [ self setEnd: end to: oldState ].
	self inTransactionOf: diagramController labeled: 'MCP: association end' do: [
		diagramController undoManager
			ifNil: [ command execute ]
			ifNotNil: [ :undoManager | undoManager execute: command ].
		(arguments at: 'navigable' ifAbsent: [ nil ]) ifNotNil: [ :navigable |
			navigable == end isNavigable ifFalse: [
				diagramController undoManager
					ifNil: [ controller viewModel writeNavigability: navigable == true to: end ]
					ifNotNil: [ :undoManager |
						undoManager execute: (OPUmlNavigabilityCommand
								 viewModel: controller viewModel
								 end: end
								 navigable: navigable == true) ] ] ] ].
	controller viewModel ifNotNil: [ :viewModel | viewModel modelChanged ].
	controller modelChanged.
	diagramController canvas signalUpdate.
	^ self elementJson: controller in: diagramController
]

{ #category : 'private' }
OPMcpTools >> setEnd: anEnd to: aState [

	anEnd
		name: (aState at: 1);
		lowerValue: (aState at: 2);
		upperValue: (aState at: 3);
		aggregation: (aState at: 4)
]

{ #category : 'private - resolving' }
OPMcpTools >> endOf: anAssociationController at: aKey in: aDiagramController [

	| ends edge type candidates |
	ends := anAssociationController model memberEnds asArray.
	edge := anAssociationController diagramElement.
	aKey = 'source' ifTrue: [ type := edge source modelElement ].
	aKey = 'target' ifTrue: [ type := edge target modelElement ].
	type ifNil: [ type := (self controllerIn: aDiagramController id: aKey) model ].
	candidates := ends select: [ :each | each type == type ].
	candidates ifEmpty: [
		OPMcpToolError signal: 'The association has no end at ' , aKey ].
	"A reflexive association has both ends at the same element: source is the first one."
	^ (aKey = 'target' and: [ candidates size > 1 ])
		  ifTrue: [ candidates last ]
		  ifFalse: [ candidates first ]
]

{ #category : 'tools' }
OPMcpTools >> undo: arguments [

	| undoManager |
	undoManager := (self workbenchFor: arguments) projectController undoManager.
	undoManager canUndo ifFalse: [ OPMcpToolError signal: 'Nothing to undo' ].
	undoManager undo.
	^ Dictionary new
		  at: 'undone' put: true;
		  yourself
]

{ #category : 'private - resolving' }
OPMcpTools >> workbenchFor: arguments [

	| workbenches key |
	workbenches := self openWorkbenches.
	key := arguments at: 'project' ifAbsent: [ nil ].
	key ifNil: [
		workbenches size = 1 ifTrue: [ ^ workbenches first ].
		workbenches ifEmpty: [
			OPMcpToolError signal:
				'No OpenPonk project is open; use create_project or open_project' ].
		OPMcpToolError signal: 'Several projects are open, pass "project": '
			, (', ' join: (workbenches collect: [ :each | each project name ])) ].
	^ workbenches
		  detect: [ :each |
			  each project uuid asString = key asString or: [ each project name = key ] ]
		  ifNone: [ OPMcpToolError signal: 'No open project "' , key asString , '"' ]
]
