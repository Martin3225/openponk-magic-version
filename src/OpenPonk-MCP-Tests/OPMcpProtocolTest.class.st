"
Tests of JSON-RPC / MCP message handling without HTTP.
"
Class {
	#name : 'OPMcpProtocolTest',
	#superclass : 'TestCase',
	#instVars : [
		'protocol'
	],
	#category : 'OpenPonk-MCP-Tests',
	#package : 'OpenPonk-MCP-Tests'
}

{ #category : 'helpers' }
OPMcpProtocolTest >> request: aMethod params: aDictionary [

	^ protocol handle: (Dictionary new
			   at: 'jsonrpc' put: '2.0';
			   at: 'id' put: 7;
			   at: 'method' put: aMethod;
			   at: 'params' put: aDictionary;
			   yourself)
]

{ #category : 'running' }
OPMcpProtocolTest >> setUp [

	super setUp.
	protocol := OPMcpProtocol new
]

{ #category : 'tests' }
OPMcpProtocolTest >> testInitializeAnswersRequestedSupportedVersion [

	| response result |
	response := self request: 'initialize' params: (Dictionary new
			             at: 'protocolVersion' put: '2025-06-18';
			             at: 'capabilities' put: Dictionary new;
			             at: 'clientInfo' put: (Dictionary new at: 'name' put: 'test'; yourself);
			             yourself).
	self assert: (response at: 'id') equals: 7.
	result := response at: 'result'.
	self assert: (result at: 'protocolVersion') equals: '2025-06-18'.
	self assert: (((result at: 'capabilities') at: 'tools') includesKey: 'listChanged').
	self assert: ((result at: 'serverInfo') at: 'name') equals: 'openponk'
]

{ #category : 'tests' }
OPMcpProtocolTest >> testInitializeWithUnknownVersionAnswersLatest [

	| result |
	result := (self request: 'initialize' params: (Dictionary new
			            at: 'protocolVersion' put: '1999-01-01';
			            yourself)) at: 'result'.
	self assert: (result at: 'protocolVersion') equals: protocol supportedProtocolVersions first
]

{ #category : 'tests' }
OPMcpProtocolTest >> testInvalidRequest [

	| response |
	response := protocol handle: (Dictionary new
			             at: 'id' put: 1;
			             at: 'method' put: 'ping';
			             yourself).
	self assert: ((response at: 'error') at: 'code') equals: -32600
]

{ #category : 'tests' }
OPMcpProtocolTest >> testNotificationsAndClientResponsesGetNoAnswer [

	self assert: (protocol handle: (Dictionary new
				  at: 'jsonrpc' put: '2.0';
				  at: 'method' put: 'notifications/initialized';
				  yourself)) isNil.
	self assert: (protocol handle: (Dictionary new
				  at: 'jsonrpc' put: '2.0';
				  at: 'id' put: 3;
				  at: 'result' put: Dictionary new;
				  yourself)) isNil
]

{ #category : 'tests' }
OPMcpProtocolTest >> testPing [

	self assert: ((self request: 'ping' params: Dictionary new) at: 'result') isEmpty
]

{ #category : 'tests' }
OPMcpProtocolTest >> testToolsListHasSchemas [

	| tools names |
	tools := (self request: 'tools/list' params: Dictionary new) at: 'result'.
	tools := tools at: 'tools'.
	names := tools collect: [ :each | each at: 'name' ].
	self assert: (names includesAll: #( 'list_projects' 'get_diagram' 'create_element'
			   'connect_elements' 'set_properties' 'duplicate_elements' 'undo'
			   'export_diagram_png' )).
	self assert: (tools allSatisfy: [ :each |
			 ((each at: 'inputSchema') at: 'type') = 'object' and: [
				 (each at: 'description') notEmpty ] ]).
	"Every tool must survive a JSON round trip."
	self assert: (NeoJSONReader fromString: (NeoJSONWriter toString: tools)) size equals: tools size
]

{ #category : 'tests' }
OPMcpProtocolTest >> testUnknownMethodAndTool [

	self
		assert: (((self request: 'resources/list' params: Dictionary new) at: 'error') at: 'code')
		equals: -32601.
	self
		assert: (((self request: 'tools/call' params: (Dictionary new
				      at: 'name' put: 'no_such_tool';
				      yourself)) at: 'error') at: 'code')
		equals: -32602
]
