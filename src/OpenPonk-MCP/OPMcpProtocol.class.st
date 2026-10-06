"
JSON-RPC 2.0 message handling of the Model Context Protocol (server side, tools only).

#handle: takes a decoded JSON message and answers the decoded response, or nil for notifications and responses (nothing to send back).
"
Class {
	#name : 'OPMcpProtocol',
	#superclass : 'Object',
	#instVars : [
		'tools'
	],
	#category : 'OpenPonk-MCP',
	#package : 'OpenPonk-MCP'
}

{ #category : 'private' }
OPMcpProtocol >> dispatch: aMethod params: aDictionary [

	aMethod = 'initialize' ifTrue: [ ^ self initializeResult: aDictionary ].
	aMethod = 'ping' ifTrue: [ ^ Dictionary new ].
	aMethod = 'tools/list' ifTrue: [
		^ Dictionary new
			  at: 'tools'
			  put: (tools definitions collect: [ :each | each asJsonDictionary ]) asArray;
			  yourself ].
	aMethod = 'tools/call' ifTrue: [
		(aDictionary at: 'name' ifAbsent: [ nil ]) isString ifFalse: [
			OPMcpProtocolError signalCode: -32602 message: 'Missing tool name' ].
		^ tools
			  call: (aDictionary at: 'name')
			  arguments: ((aDictionary at: 'arguments' ifAbsent: [ nil ]) ifNil: [ Dictionary new ]) ].
	OPMcpProtocolError signalCode: -32601 message: 'Method not found: ' , aMethod asString
]

{ #category : 'private' }
OPMcpProtocol >> errorResponse: aCode message: aString id: anId [

	^ OrderedDictionary new
		  at: 'jsonrpc' put: '2.0';
		  at: 'id' put: anId;
		  at: 'error' put: (OrderedDictionary new
				   at: 'code' put: aCode;
				   at: 'message' put: aString;
				   yourself);
		  yourself
]

{ #category : 'handling' }
OPMcpProtocol >> handle: aMessage [

	| responses |
	aMessage isArray ifFalse: [ ^ self handleSingle: aMessage ].
	responses := (aMessage collect: [ :each | self handleSingle: each ])
		             reject: [ :each | each isNil ].
	^ responses ifEmpty: [ nil ]
]

{ #category : 'handling' }
OPMcpProtocol >> handleSingle: aMessage [

	| id isNotification method result |
	(aMessage isDictionary and: [ (aMessage at: 'jsonrpc' ifAbsent: [ nil ]) = '2.0' ])
		ifFalse: [ ^ self errorResponse: -32600 message: 'Invalid Request' id: nil ].
	id := aMessage at: 'id' ifAbsent: [ nil ].
	isNotification := (aMessage includesKey: 'id') not.
	method := aMessage at: 'method' ifAbsent: [ nil ].
	method ifNil: [
		"A response to a server request; this server sends none, so nothing to do."
		^ isNotification
			  ifTrue: [ self errorResponse: -32600 message: 'Invalid Request' id: nil ]
			  ifFalse: [ nil ] ].
	isNotification ifTrue: [ ^ nil ].
	result := [
	          self
		          dispatch: method
		          params: ((aMessage at: 'params' ifAbsent: [ nil ]) ifNil: [ Dictionary new ]) ]
		          on: OPMcpProtocolError
		          do: [ :error |
		          ^ self errorResponse: error code message: error messageText id: id ].
	^ OrderedDictionary new
		  at: 'jsonrpc' put: '2.0';
		  at: 'id' put: id;
		  at: 'result' put: result;
		  yourself
]

{ #category : 'initialization' }
OPMcpProtocol >> initialize [

	super initialize.
	tools := OPMcpTools new
]

{ #category : 'private' }
OPMcpProtocol >> initializeResult: aDictionary [

	| requested |
	requested := aDictionary at: 'protocolVersion' ifAbsent: [ nil ].
	^ OrderedDictionary new
		  at: 'protocolVersion' put: ((self supportedProtocolVersions includes: requested)
				   ifTrue: [ requested ]
				   ifFalse: [ self supportedProtocolVersions first ]);
		  at: 'capabilities' put: (Dictionary new
				   at: 'tools' put: (Dictionary new
						    at: 'listChanged' put: false;
						    yourself);
				   yourself);
		  at: 'serverInfo' put: (OrderedDictionary new
				   at: 'name' put: 'openponk';
				   at: 'title' put: 'OpenPonk';
				   at: 'version' put: '0.1.0';
				   yourself);
		  at: 'instructions' put: self instructions;
		  yourself
]

{ #category : 'accessing' }
OPMcpProtocol >> instructions [

	^ 'Tools for the OpenPonk modeling tool running on this computer (UML/OntoUML class diagrams, ER, BPMN, BORM, DEMO, FSM, Petri nets, Markov chains). Start with list_projects (or create_project / open_project), then get_diagram and list_element_types. Element types are the labels of the diagram''s palette. Elements are addressed by the ids that get_diagram returns. Every change is a normal undoable step in OpenPonk (undo tool or Cmd/Ctrl+Z in the app). export_diagram_png shows the diagram as an image.'
]

{ #category : 'accessing' }
OPMcpProtocol >> supportedProtocolVersions [
	"Newest first; answered when the client asks for an unknown version."

	^ #( '2025-11-25' '2025-06-18' '2025-03-26' '2024-11-05' )
]

{ #category : 'accessing' }
OPMcpProtocol >> tools [

	^ tools
]
