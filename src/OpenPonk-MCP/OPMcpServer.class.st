"
MCP server of OpenPonk (Streamable HTTP transport, JSON responses only).

It listens on 127.0.0.1 only, at http://127.0.0.1:<port>/mcp (default port 47100, or the OPENPONK_MCP_PORT environment variable), and rejects requests whose Origin header is not a local page (protection against DNS rebinding from web pages).

	OPMcpServer startDefault.
	OPMcpServer stopDefault.
	OPMcpServer autoStart: true. ""start with the image""
"
Class {
	#name : 'OPMcpServer',
	#superclass : 'Object',
	#instVars : [
		'port',
		'server',
		'protocol'
	],
	#classVars : [
		'AutoStart',
		'Default'
	],
	#category : 'OpenPonk-MCP',
	#package : 'OpenPonk-MCP'
}

{ #category : 'settings' }
OPMcpServer class >> autoStart [

	^ AutoStart == true
]

{ #category : 'settings' }
OPMcpServer class >> autoStart: aBoolean [

	AutoStart := aBoolean
]

{ #category : 'accessing' }
OPMcpServer class >> default [

	^ Default
]

{ #category : 'settings' }
OPMcpServer class >> defaultPort [

	^ (OSEnvironment current at: 'OPENPONK_MCP_PORT' ifAbsent: [ nil ])
		  ifNotNil: [ :value | value asNumber ]
		  ifNil: [ 47100 ]
]

{ #category : 'class initialization' }
OPMcpServer class >> initialize [

	SessionManager default registerUserClassNamed: self name
]

{ #category : 'instance creation' }
OPMcpServer class >> onPort: aNumber [

	^ self new
		  port: aNumber;
		  yourself
]

{ #category : 'system startup' }
OPMcpServer class >> shutDown: isImageQuitting [

	isImageQuitting ifTrue: [ self stopDefault ]
]

{ #category : 'starting' }
OPMcpServer class >> startDefault [

	self stopDefault.
	Default := (self onPort: self defaultPort) start.
	^ Default
]

{ #category : 'system startup' }
OPMcpServer class >> startUp: isImageStarting [
	"Sockets of a saved image are dead, start over."

	isImageStarting ifFalse: [ ^ self ].
	Default := nil.
	self autoStart ifTrue: [
		[ self startDefault ]
			on: Error
			do: [ :error |
				self traceCr: 'OpenPonk MCP server did not start: ' , error messageText ] ]
]

{ #category : 'starting' }
OPMcpServer class >> stopDefault [

	Default ifNotNil: [ :running | running stop ].
	Default := nil
]

{ #category : 'private' }
OPMcpServer >> emptyResponse: aStatusCode [
	"Without Content-Length a keep-alive client would wait for a body until the connection closes."

	| response |
	response := ZnResponse statusCode: aStatusCode.
	response headers at: 'Content-Length' put: '0'.
	^ response
]

{ #category : 'private' }
OPMcpServer >> ensurePortIsFree [
	"ZnServer opens its socket in a forked process, where a busy port would end in an unhandled error (a debugger in the GUI). Find out here instead."

	| socket |
	socket := [
	          ZnNetworkingUtils
		          serverSocketOn: port
		          interface: NetNameResolver loopBackAddress ]
		          on: NetworkError
		          do: [ :error |
			          Error signal: 'Port ' , port printString , ' is already in use' ].
	socket closeAndDestroy
]

{ #category : 'private' }
OPMcpServer >> handlePost: aRequest [

	| message reply |
	message := [ NeoJSONReader fromString: (self utf8BodyOf: aRequest) ]
		           on: Error
		           do: [
			           ^ self jsonResponse: (protocol
					              errorResponse: -32700
					              message: 'Parse error'
					              id: nil) ].
	reply := protocol handle: message.
	reply ifNil: [ ^ self emptyResponse: 202 ].
	^ self jsonResponse: reply
]

{ #category : 'request handling' }
OPMcpServer >> handleRequest: aRequest [
	"ZnServer delegate entry point."

	| response |
	aRequest uri pathPrintString = '/mcp' ifFalse: [
		^ ZnResponse notFound: aRequest uri ].
	(self isAllowedOrigin: (aRequest headers at: 'Origin' ifAbsent: [ nil ]))
		ifFalse: [
			^ (ZnResponse statusCode: 403)
				  entity: (ZnEntity text: 'Origin not allowed');
				  yourself ].
	aRequest method = #POST ifTrue: [ ^ self handlePost: aRequest ].
	response := self emptyResponse: 405.
	response headers at: 'Allow' put: 'POST'.
	^ response
]

{ #category : 'initialization' }
OPMcpServer >> initialize [

	super initialize.
	port := self class defaultPort.
	protocol := OPMcpProtocol new
]

{ #category : 'private' }
OPMcpServer >> isAllowedOrigin: anOriginOrNil [
	"No Origin means a non-browser client. Browsers may only call from local pages."

	| host |
	anOriginOrNil ifNil: [ ^ true ].
	host := [ anOriginOrNil asZnUrl host ]
		        on: Error
		        do: [ ^ false ].
	^ #( 'localhost' '127.0.0.1' '[::1]' '::1' ) includes: host
]

{ #category : 'testing' }
OPMcpServer >> isRunning [

	^ server isNotNil and: [ server isRunning ]
]

{ #category : 'private' }
OPMcpServer >> jsonResponse: anObject [

	^ ZnResponse ok: (ZnEntity
			   with: (NeoJSONWriter toString: anObject)
			   type: (ZnMimeType applicationJson
					    charSet: 'utf-8';
					    yourself))
]

{ #category : 'accessing' }
OPMcpServer >> port [

	^ port
]

{ #category : 'accessing' }
OPMcpServer >> port: aNumber [

	port := aNumber
]

{ #category : 'accessing' }
OPMcpServer >> protocol [

	^ protocol
]

{ #category : 'starting' }
OPMcpServer >> start [

	self stop.
	self ensurePortIsFree.
	server := (ZnServer defaultServerClass on: port)
		          bindingAddress: NetNameResolver loopBackAddress;
		          delegate: self;
		          yourself.
	server start.
	self waitUntilRunning ifFalse: [
		self stop.
		Error signal: 'Could not listen on 127.0.0.1:' , port printString ].
	^ self
]

{ #category : 'starting' }
OPMcpServer >> stop [

	server ifNotNil: [ :running | running stop ].
	server := nil
]

{ #category : 'private' }
OPMcpServer >> waitUntilRunning [

	40 timesRepeat: [
		server isRunning ifTrue: [ ^ true ].
		(Delay forMilliseconds: 50) wait ].
	^ server isRunning
]

{ #category : 'accessing' }
OPMcpServer >> url [

	^ 'http://127.0.0.1:' , port printString , '/mcp'
]

{ #category : 'private' }
OPMcpServer >> utf8BodyOf: aRequest [
	"JSON is UTF-8; do not rely on a charset parameter the client may omit."

	| entity |
	entity := aRequest entity ifNil: [ ^ '' ].
	^ (entity respondsTo: #bytes)
		  ifTrue: [ entity bytes utf8Decoded ]
		  ifFalse: [ entity contents ]
]
