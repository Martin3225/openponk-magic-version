"
Tests of the HTTP side of the MCP server (Streamable HTTP with JSON responses) on a spare local port.
"
Class {
	#name : 'OPMcpServerTest',
	#superclass : 'TestCase',
	#instVars : [
		'server'
	],
	#category : 'OpenPonk-MCP-Tests',
	#package : 'OpenPonk-MCP-Tests'
}

{ #category : 'helpers' }
OPMcpServerTest >> post: aString [

	^ self post: aString origin: nil
]

{ #category : 'helpers' }
OPMcpServerTest >> post: aString origin: anOriginOrNil [

	| client |
	client := ZnClient new
		          url: server url;
		          accept: 'application/json, text/event-stream';
		          enforceHttpSuccess: false;
		          entity: (ZnEntity
				           with: aString
				           type: (ZnMimeType applicationJson
						            charSet: 'utf-8';
						            yourself));
		          yourself.
	anOriginOrNil ifNotNil: [ client headerAt: 'Origin' put: anOriginOrNil ].
	"Close the connection, so that no server worker is left waiting on it when the server stops."
	^ [
	  client post.
	  client response ] ensure: [ client close ]
]

{ #category : 'running' }
OPMcpServerTest >> setUp [

	super setUp.
	server := OPMcpServer onPort: 47199.
	[ server start ]
		on: Error
		do: [ self skip: 'Port 47199 is not available' ]
]

{ #category : 'running' }
OPMcpServerTest >> tearDown [

	server ifNotNil: [ server stop ].
	super tearDown
]

{ #category : 'tests' }
OPMcpServerTest >> testGetIsNotAllowed [

	| client response |
	client := ZnClient new
		          url: server url;
		          enforceHttpSuccess: false;
		          yourself.
	response := [
	            client get.
	            client response ] ensure: [ client close ].
	self assert: response code equals: 405.
	self assert: (response headers at: 'Allow') equals: 'POST'
]

{ #category : 'tests' }
OPMcpServerTest >> testInitializeOverHttp [

	| response json |
	response := self post:
		            '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}'.
	self assert: response code equals: 200.
	self assert: response contentType main equals: 'application'.
	json := NeoJSONReader fromString: response contents.
	self assert: ((json at: 'result') at: 'protocolVersion') equals: '2025-06-18'
]

{ #category : 'tests' }
OPMcpServerTest >> testNotificationIsAccepted [

	self
		assert: (self post: '{"jsonrpc":"2.0","method":"notifications/initialized"}') code
		equals: 202
]

{ #category : 'tests' }
OPMcpServerTest >> testOnlyLocalOriginsAreAllowed [

	| ping |
	ping := '{"jsonrpc":"2.0","id":2,"method":"ping"}'.
	self assert: (self post: ping origin: 'http://evil.example') code equals: 403.
	self assert: (self post: ping origin: 'http://localhost:5173') code equals: 200.
	self assert: (self post: ping origin: 'http://127.0.0.1') code equals: 200
]

{ #category : 'tests' }
OPMcpServerTest >> testParseError [

	| json |
	json := NeoJSONReader fromString: (self post: '{not json') contents.
	self assert: ((json at: 'error') at: 'code') equals: -32700
]

{ #category : 'tests' }
OPMcpServerTest >> testToolCallKeepsUtf8 [

	| response text |
	response := self post:
		            '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"no_such_tool_ěščř","arguments":{}}}'.
	text := ((NeoJSONReader fromString: response contents) at: 'error') at: 'message'.
	self assert: (text includesSubstring: 'no_such_tool_ěščř').
	response := self post:
		            '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"list_notations","arguments":{}}}'.
	text := (((NeoJSONReader fromString: response contents) at: 'result') at: 'content') first at: 'text'.
	self assert: (text includesSubstring: 'UML Class Editor')
]
