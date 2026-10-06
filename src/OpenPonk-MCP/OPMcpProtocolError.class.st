"
JSON-RPC error (unknown method, invalid params...) answered as an error response.
"
Class {
	#name : 'OPMcpProtocolError',
	#superclass : 'Error',
	#instVars : [
		'code'
	],
	#category : 'OpenPonk-MCP',
	#package : 'OpenPonk-MCP'
}

{ #category : 'signalling' }
OPMcpProtocolError class >> signalCode: anInteger message: aString [

	^ self new
		  code: anInteger;
		  signal: aString
]

{ #category : 'accessing' }
OPMcpProtocolError >> code [

	^ code
]

{ #category : 'accessing' }
OPMcpProtocolError >> code: anInteger [

	code := anInteger
]
