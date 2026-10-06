"
Tests of the MCP tools against real OpenPonk projects opened in workbenches (headless, so tools run directly instead of in the UI process).
"
Class {
	#name : 'OPMcpToolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'tools',
		'projectIds',
		'files'
	],
	#category : 'OpenPonk-MCP-Tests',
	#package : 'OpenPonk-MCP-Tests'
}

{ #category : 'accessing' }
OPMcpToolsTest class >> defaultTimeLimit [

	^ 2 minutes
]

{ #category : 'helpers' }
OPMcpToolsTest >> call: aToolName with: anArray [
	"Call a tool that must succeed and answer its JSON result decoded."

	| result |
	result := tools call: aToolName arguments: anArray asDictionary.
	self deny: (result at: 'isError') description: [ ((result at: 'content') first at: 'text') ].
	^ NeoJSONReader fromString: ((result at: 'content') first at: 'text')
]

{ #category : 'helpers' }
OPMcpToolsTest >> errorOf: aToolName with: anArray [
	"Call a tool that must fail and answer its error message."

	| result |
	result := tools call: aToolName arguments: anArray asDictionary.
	self assert: (result at: 'isError').
	^ (result at: 'content') first at: 'text'
]

{ #category : 'helpers' }
OPMcpToolsTest >> newUmlProject [

	| project |
	project := self call: 'create_project' with: {
			           ('name' -> 'MCP žluťoučký test').
			           ('notation' -> 'UML Class Editor') }.
	projectIds add: (project at: 'id').
	^ project at: 'id'
]

{ #category : 'running' }
OPMcpToolsTest >> setUp [

	super setUp.
	tools := OPMcpTools new.
	projectIds := OrderedCollection new.
	files := OrderedCollection new
]

{ #category : 'running' }
OPMcpToolsTest >> tearDown [

	tools openWorkbenches do: [ :each |
		(projectIds includes: each project uuid asString) ifTrue: [
			each application closeAllWindows ] ].
	files do: [ :each | each asFileReference ensureDelete ].
	super tearDown
]

{ #category : 'tests' }
OPMcpToolsTest >> testBuildUmlDiagram [

	| project types person attribute address association diagram elements copies png |
	project := self newUmlProject.
	types := (self call: 'list_element_types' with: { ('project' -> project) }) at: 'types'.
	self assert: (types detect: [ :each | (each at: 'type') = 'Class' ]) equals: (Dictionary new
			 at: 'type' put: 'Class';
			 at: 'kind' put: 'node';
			 at: 'topLevel' put: true;
			 yourself).
	self assert: ((types detect: [ :each | (each at: 'type') = 'Attribute' ]) at: 'topLevel') equals: false.
	self assert: ((types detect: [ :each | (each at: 'type') = 'Association' ]) at: 'kind') equals: 'edge'.

	person := self call: 'create_element' with: {
			          ('project' -> project).
			          ('type' -> 'class').
			          ('name' -> 'Osoba').
			          ('x' -> 100).
			          ('y' -> 120) }.
	self assert: (person at: 'name') equals: 'Osoba'.
	self assert: (person at: 'x') equals: 100.
	address := self call: 'create_element' with: {
			           ('project' -> project).
			           ('type' -> 'Class').
			           ('name' -> 'Address') }.
	self assert: (address at: 'x') > ((person at: 'x') + (person at: 'width')).
	attribute := self call: 'create_element' with: {
			             ('project' -> project).
			             ('type' -> 'Attribute').
			             ('parent' -> (person at: 'id')).
			             ('name' -> 'home') }.
	self assert: (attribute at: 'parent') equals: (person at: 'id').
	attribute := self call: 'set_properties' with: {
			             ('project' -> project).
			             ('element' -> (attribute at: 'id')).
			             ('properties' -> (Dictionary new
				               at: 'type' put: 'Address';
				               at: 'multiplicity' put: '0..*';
				               yourself)) }.
	self assert: ((attribute at: 'properties') at: 'type') equals: 'Address'.
	self assert: ((attribute at: 'properties') at: 'multiplicity') equals: '0..*'.
	attribute := self call: 'set_properties' with: {
			             ('project' -> project).
			             ('element' -> (attribute at: 'id')).
			             ('properties' -> (Dictionary new
				               at: 'multiplicity' put: '0,5...2,5';
				               yourself)) }.
	self assert: ((attribute at: 'properties') at: 'multiplicity') equals: '0.5..2.5'.
	self assert: ((self errorOf: 'set_properties' with: {
				  ('project' -> project).
				  ('element' -> (attribute at: 'id')).
				  ('properties' -> (Dictionary new
					    at: 'multiplicity' put: '3..1';
					    yourself)) }) includesSubstring: 'Invalid multiplicity').
	association := self call: 'connect_elements' with: {
			               ('project' -> project).
			               ('type' -> 'Association').
			               ('source' -> (person at: 'id')).
			               ('target' -> (address at: 'id')) }.
	self assert: (association at: 'kind') equals: 'edge'.
	self assert: (association at: 'source') equals: (person at: 'id').
	self assert: (association at: 'target') equals: (address at: 'id').
	person := self call: 'set_properties' with: {
			          ('project' -> project).
			          ('element' -> (person at: 'id')).
			          ('properties' -> (Dictionary new
				            at: 'isAbstract' put: true;
				            yourself)) }.
	person := self call: 'move_element' with: {
			          ('project' -> project).
			          ('element' -> (person at: 'id')).
			          ('x' -> 50).
			          ('y' -> 300).
			          ('width' -> 160) }.
	self assert: (person at: 'x') equals: 50.
	self assert: (person at: 'y') equals: 300.
	"x, y is the top-left corner of what is drawn (a class sizes itself to its content)"
	self
		assert: (tools
				 controllerIn: (tools diagramControllerFor: (Dictionary new at: 'project' put: project; yourself))
				 id: (person at: 'id')) roassalShape encompassingRectangle left floor
		equals: 50.
	self assert: ((person at: 'properties') at: 'isAbstract').

	diagram := self call: 'get_diagram' with: { ('project' -> project) }.
	elements := diagram at: 'elements'.
	self
		assert: (elements collect: [ :each | each at: 'kind' ]) asBag
		equals: #( 'node' 'node' 'node' 'edge' ) asBag.
	self assert: (((elements detect: [ :each | (each at: 'kind') = 'edge' ]) at: 'properties') at: 'ends') size equals: 2.

	copies := (self call: 'duplicate_elements' with: {
			           ('project' -> project).
			           ('elements' -> { (person at: 'id') }) }) at: 'copies'.
	self assert: copies size equals: 1.
	self assert: ((self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements') size equals: 6.
	self call: 'undo' with: { ('project' -> project) }.
	self assert: ((self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements') size equals: 4.
	self call: 'redo' with: { ('project' -> project) }.
	self assert: ((self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements') size equals: 6.

	self call: 'delete_elements' with: {
			('project' -> project).
			('elements' -> { (address at: 'id') }) }.
	elements := (self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements'.
	self deny: (elements anySatisfy: [ :each | (each at: 'kind') = 'edge' ]).
	self deny: (elements anySatisfy: [ :each | (each at: 'id') = (address at: 'id') ]).

	png := tools call: 'export_diagram_png' arguments: (Dictionary new at: 'project' put: project; yourself).
	self deny: (png at: 'isError').
	self assert: ((png at: 'content') first at: 'mimeType') equals: 'image/png'.
	self assert: (((png at: 'content') first at: 'data') base64Decoded first: 4) equals: #[137 80 78 71].
	"The whole diagram, not the part the (headless, tiny) editor shows."
	self assert: (PNGReadWriter formFromStream: ((png at: 'content') first at: 'data') base64Decoded readStream) width
		> ((self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements') size
]

{ #category : 'tests' }
OPMcpToolsTest >> testBuildErDiagram [
	"In ER diagrams the target of a connection is validated against its source."

	| project student key relation elements |
	project := self call: 'create_project' with: {
			           ('name' -> 'ER přes MCP').
			           ('notation' -> 'ER Diagram') }.
	projectIds add: (project at: 'id').
	project := project at: 'id'.
	student := self call: 'create_element' with: {
			           ('project' -> project).
			           ('type' -> 'Regular Entity').
			           ('name' -> 'Student') }.
	key := self call: 'create_element' with: {
			       ('project' -> project).
			       ('type' -> 'Key Attribute').
			       ('name' -> 'číslo') }.
	relation := self call: 'create_element' with: {
			            ('project' -> project).
			            ('type' -> 'Regular Relation').
			            ('name' -> 'zapsán') }.
	self call: 'connect_elements' with: {
			('project' -> project).
			('type' -> 'Regular Connection').
			('source' -> (key at: 'id')).
			('target' -> (student at: 'id')) }.
	self call: 'connect_elements' with: {
			('project' -> project).
			('type' -> 'Total Connection').
			('source' -> (relation at: 'id')).
			('target' -> (student at: 'id')) }.
	self assert: ((self errorOf: 'connect_elements' with: {
				  ('project' -> project).
				  ('type' -> 'Regular Connection').
				  ('source' -> (student at: 'id')).
				  ('target' -> (student at: 'id')) }) includesSubstring: 'cannot be').
	elements := (self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements'.
	self assert: (elements select: [ :each | (each at: 'kind') = 'edge' ]) size equals: 2.
	self assert: ((elements detect: [ :each | (each at: 'name') = 'číslo' ]) at: 'properties') equals: (Dictionary new
			 at: 'isKey' put: true;
			 at: 'isDerived' put: false;
			 at: 'isMultivalued' put: false;
			 yourself)
]

{ #category : 'tests' }
OPMcpToolsTest >> testBuildOntoUmlDiagram [
	"Stereotyped palette entries of OntoUML apply their stereotype; stereotypes can be changed and undone."

	| project person student enrollment mediation |
	project := self call: 'create_project' with: {
			           ('name' -> 'OntoUML přes MCP').
			           ('notation' -> 'OntoUML') }.
	projectIds add: (project at: 'id').
	self assert: ((project at: 'diagrams') first at: 'notation') equals: 'OntoUML UFO-A'.
	project := project at: 'id'.
	person := self call: 'create_element' with: {
			          ('project' -> project).
			          ('type' -> 'Kind').
			          ('name' -> 'Person') }.
	self assert: ((person at: 'properties') at: 'stereotypes') equals: #( 'Kind' ).
	self assert: (person at: 'name') equals: 'Person'.
	student := self call: 'create_element' with: {
			           ('project' -> project).
			           ('type' -> 'Role').
			           ('name' -> 'Student') }.
	enrollment := self call: 'create_element' with: {
			              ('project' -> project).
			              ('type' -> 'Relator').
			              ('name' -> 'Enrollment') }.
	self call: 'connect_elements' with: {
			('project' -> project).
			('type' -> 'Generalization').
			('source' -> (student at: 'id')).
			('target' -> (person at: 'id')) }.
	mediation := self call: 'connect_elements' with: {
			             ('project' -> project).
			             ('type' -> 'Mediation').
			             ('source' -> (enrollment at: 'id')).
			             ('target' -> (student at: 'id')) }.
	self assert: ((mediation at: 'properties') at: 'stereotypes') equals: #( 'Mediation' ).

	student := self call: 'set_properties' with: {
			           ('project' -> project).
			           ('element' -> (student at: 'id')).
			           ('properties' -> (Dictionary new
				             at: 'stereotype' put: 'SubKind';
				             yourself)) }.
	self assert: ((student at: 'properties') at: 'stereotypes') equals: #( 'SubKind' ).
	self call: 'undo' with: { ('project' -> project) }.
	self
		assert: (((((self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements')
				   detect: [ :each | (each at: 'id') = (student at: 'id') ]) at: 'properties') at: 'stereotypes')
		equals: #( 'Role' ).
	self assert: ((self errorOf: 'set_properties' with: {
				  ('project' -> project).
				  ('element' -> (person at: 'id')).
				  ('properties' -> (Dictionary new
					    at: 'stereotype' put: 'Unicorn';
					    yourself)) }) includesSubstring: 'SubKind')
]

{ #category : 'tests' }
OPMcpToolsTest >> testAssociationEndsAndGeneralizationSets [

	| project library branch book association ends generalizations set first second edges |
	project := self newUmlProject.
	library := self call: 'create_element' with: {
			         ('project' -> project).
			         ('type' -> 'Class').
			         ('name' -> 'Library') }.
	branch := self call: 'create_element' with: {
			         ('project' -> project).
			         ('type' -> 'Class').
			         ('name' -> 'Branch') }.
	association := self call: 'connect_elements' with: {
			               ('project' -> project).
			               ('type' -> 'Association').
			               ('source' -> (branch at: 'id')).
			               ('target' -> (library at: 'id')) }.
	self call: 'set_association_end' with: {
			('project' -> project).
			('element' -> (association at: 'id')).
			('at' -> (branch at: 'id')).
			('name' -> 'branches').
			('multiplicity' -> '0..*').
			('aggregation' -> 'composite') }.
	association := self call: 'set_association_end' with: {
			               ('project' -> project).
			               ('element' -> (association at: 'id')).
			               ('at' -> 'target').
			               ('multiplicity' -> '1').
			               ('navigable' -> true) }.
	ends := (association at: 'properties') at: 'ends'.
	first := ends detect: [ :each | (each at: 'type') = 'Branch' ].
	second := ends detect: [ :each | (each at: 'type') = 'Library' ].
	self assert: (first at: 'name') equals: 'branches'.
	self assert: (first at: 'multiplicity') equals: '0..*'.
	self assert: (first at: 'aggregation') equals: 'composite'.
	self assert: (second at: 'multiplicity') equals: '1'.
	self assert: (second at: 'navigable').
	self assert: ((self errorOf: 'set_association_end' with: {
				  ('project' -> project).
				  ('element' -> (association at: 'id')).
				  ('at' -> 'source').
				  ('multiplicity' -> 'many') }) includesSubstring: 'Invalid multiplicity').
	self call: 'undo' with: { ('project' -> project) }.
	self call: 'undo' with: { ('project' -> project) }.
	ends := (((self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements')
		         detect: [ :each | (each at: 'kind') = 'edge' ]) at: 'properties'.
	self deny: (((ends at: 'ends') detect: [ :each | (each at: 'type') = 'Branch' ])
			 includesKey: 'aggregation').

	book := self call: 'create_element' with: {
			       ('project' -> project).
			       ('type' -> 'Class').
			       ('name' -> 'Book') }.
	generalizations := #( 'Novel' 'Textbook' ) collect: [ :each |
		                   | sub |
		                   sub := self call: 'create_element' with: {
				                          ('project' -> project).
				                          ('type' -> 'Class').
				                          ('name' -> each) }.
		                   (self call: 'connect_elements' with: {
				                    ('project' -> project).
				                    ('type' -> 'Generalization').
				                    ('source' -> (sub at: 'id')).
				                    ('target' -> (book at: 'id')) }) at: 'id' ].
	set := self call: 'create_generalization_set' with: {
			       ('project' -> project).
			       ('generalizations' -> generalizations).
			       ('disjoint' -> true).
			       ('covering' -> true) }.
	self assert: (set at: 'generalizations') asSet equals: generalizations asSet.
	edges := ((self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements') select: [ :each |
		         generalizations includes: (each at: 'id') ].
	self assert: (edges allSatisfy: [ :each |
			 (((each at: 'properties') at: 'generalizationSets') first at: 'disjoint') ]).
	self assert: ((self errorOf: 'create_generalization_set' with: {
				  ('project' -> project).
				  ('generalizations' -> { generalizations first. (association at: 'id') }).
				  ('disjoint' -> true).
				  ('covering' -> false) }) includesSubstring: 'generalizations').
	self call: 'undo' with: { ('project' -> project) }.
	edges := ((self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements') select: [ :each |
		         generalizations includes: (each at: 'id') ].
	self deny: (edges anySatisfy: [ :each |
			 (each at: 'properties' ifAbsent: [ Dictionary new ]) includesKey: 'generalizationSets' ])
]

{ #category : 'tests' }
OPMcpToolsTest >> testAutoLayout [

	| project first second result |
	project := self newUmlProject.
	first := self call: 'create_element' with: {
			         ('project' -> project).
			         ('type' -> 'Class').
			         ('name' -> 'A').
			         ('x' -> 100).
			         ('y' -> 100) }.
	second := self call: 'create_element' with: {
			          ('project' -> project).
			          ('type' -> 'Class').
			          ('name' -> 'B').
			          ('x' -> 110).
			          ('y' -> 110) }.
	result := self call: 'auto_layout' with: { ('project' -> project) }.
	self assert: (result at: 'algorithm') equals: 'tidy'.
	first := (result at: 'elements') detect: [ :each | (each at: 'name') = 'A' ].
	second := (result at: 'elements') detect: [ :each | (each at: 'name') = 'B' ].
	self deny: (((first at: 'x') @ (first at: 'y') extent: (first at: 'width') @ (first at: 'height'))
			 intersects: ((second at: 'x') @ (second at: 'y') extent: (second at: 'width') @ (second at: 'height'))).
	self call: 'auto_layout' with: {
			('project' -> project).
			('algorithm' -> 'grid') }.
	self assert: ((self errorOf: 'auto_layout' with: {
				  ('project' -> project).
				  ('algorithm' -> 'spiral') }) includesSubstring: 'tidy')
]

{ #category : 'tests' }
OPMcpToolsTest >> testErrorsAreToolResults [

	| project |
	project := self newUmlProject.
	self assert: ((self errorOf: 'create_element' with: {
				  ('project' -> project).
				  ('type' -> 'Unicorn') }) includesSubstring: 'Class').
	self assert: ((self errorOf: 'create_element' with: {
				  ('project' -> project).
				  ('type' -> 'Attribute') }) includesSubstring: 'parent').
	self assert: ((self errorOf: 'set_properties' with: {
				  ('project' -> project).
				  ('element' -> 'nope').
				  ('properties' -> Dictionary new) }) includesSubstring: 'get_diagram').
	self assert: ((self errorOf: 'get_diagram' with: { ('project' -> 'no such project') })
			 includesSubstring: 'no such project').
	self assert: ((self errorOf: 'create_project' with: {
				  ('name' -> 'x').
				  ('notation' -> 'Klingon') }) includesSubstring: 'BPMN')
]

{ #category : 'tests' }
OPMcpToolsTest >> testProjectLifecycle [

	| project listed file reopened notations |
	notations := self call: 'list_notations' with: {  }.
	self assert: (notations includes: 'ER Diagram').
	project := self newUmlProject.
	listed := (self call: 'list_projects' with: {  }) detect: [ :each | (each at: 'id') = project ].
	self assert: (listed at: 'name') equals: 'MCP žluťoučký test'.
	"A UML package without profiles is claimed by the first matching plugin, which in OpenPonk itself is OntoUML."
	self assert: (#( 'UML Class Editor' 'OntoUML UFO-A' ) includes: ((listed at: 'diagrams') first at: 'notation')).
	self assert: ((self errorOf: 'save_project' with: { ('project' -> project) }) includesSubstring: 'path').
	self call: 'create_element' with: {
			('project' -> project).
			('type' -> 'Class').
			('name' -> 'Kůň') }.
	file := FileLocator temp / ('mcp-test-' , UUID new asString , '.opp').
	files add: file.
	self call: 'save_project' with: {
			('project' -> project).
			('path' -> file fullName) }.
	self assert: file exists.
	self call: 'save_project' with: { ('project' -> project) }.

	reopened := self call: 'open_project' with: { ('path' -> file fullName) }.
	self assert: (reopened at: 'name') equals: 'MCP žluťoučký test'.
	self assert: ((self errorOf: 'get_diagram' with: {  }) includesSubstring: 'Several projects').
	self assert: (((self call: 'get_diagram' with: { ('project' -> (reopened at: 'id')) }) at: 'elements')
			 anySatisfy: [ :each | (each at: 'name') = 'Kůň' ])
]

{ #category : 'tests' }
OPMcpToolsTest >> testOntoUmlTextPatternsAndCheck [
	"create_from_text and apply_pattern add OntoUML elements, verify_model explains what breaks the rules."

	| project plan created check problem patterns error |
	project := self call: 'create_project' with: {
			           ('name' -> 'OntoUML text').
			           ('notation' -> 'OntoUML') }.
	projectIds add: (project at: 'id').
	project := project at: 'id'.

	plan := self call: 'create_from_text' with: {
			        ('project' -> project).
			        ('text' -> 'Person : Kind
Student : Role -> Person').
			        ('dry_run' -> true) }.
	self deny: (plan at: 'applied').
	self assert: (plan at: 'plan') equals: #( '+ class «Person» (Kind)' '+ class «Student» (Role)' '+ generalization Student → Person' ).
	self assert: ((self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements') isEmpty.

	created := self call: 'create_from_text' with: {
			           ('project' -> project).
			           ('text' -> 'Person : Kind
Student : Role -> Person') }.
	self assert: (created at: 'applied').
	self assert: (created at: 'created') size equals: 3.

	check := self call: 'verify_model' with: { ('project' -> project) }.
	self assert: (check at: 'errors') equals: 1.
	problem := (check at: 'problems') first.
	self assert: (problem at: 'rule') equals: 'roleWithoutRelator'.
	self assert: (problem at: 'elementName') equals: 'Student'.
	self assert: (problem at: 'element') equals: (((created at: 'created') detect: [ :each | (each at: 'name') = 'Student' ]) at: 'id').
	self assert: (problem at: 'title') equals: 'Role «Student» is not defined by a relationship'.
	self
		assert: (((self call: 'verify_model' with: {
					    ('project' -> project).
					    ('language' -> 'cs') }) at: 'problems') first at: 'title')
		equals: 'Role «Student» není definovaná vztahem'.

	error := self errorOf: 'create_from_text' with: {
			         ('project' -> project).
			         ('text' -> 'Study : Relatr') }.
	self assert: (error includesSubstring: 'Line 1: unknown stereotype «Relatr», did you mean «Relator»?').

	patterns := (self call: 'list_patterns' with: {  }) at: 'patterns'.
	self assert: (patterns collect: [ :each | each at: 'id' ]) asArray equals: #( 'phases' 'relator' 'roleMixin' 'properties' 'parts' ).
	self call: 'apply_pattern' with: {
			('project' -> project).
			('pattern' -> 'relator') }.
	"The pattern reuses Person and Student, and its relator defines the role."
	check := self call: 'verify_model' with: { ('project' -> project) }.
	self assert: (check at: 'errors') equals: 0.
	self assert: (((self call: 'get_diagram' with: { ('project' -> project) }) at: 'elements') count: [ :each |
			 (each at: 'name') = 'Person' ]) equals: 1
]
