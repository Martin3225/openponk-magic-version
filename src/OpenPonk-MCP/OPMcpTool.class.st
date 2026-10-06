"
Definition of one MCP tool: name, description, JSON schema of its arguments and the OPMcpTools selector implementing it.
"
Class {
	#name : 'OPMcpTool',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'inputSchema',
		'selector',
		'returnsContent'
	],
	#category : 'OpenPonk-MCP',
	#package : 'OpenPonk-MCP'
}

{ #category : 'converting' }
OPMcpTool >> asJsonDictionary [

	^ OrderedDictionary new
		  at: 'name' put: name;
		  at: 'description' put: description;
		  at: 'inputSchema' put: inputSchema;
		  yourself
]

{ #category : 'accessing' }
OPMcpTool >> description: aString [

	description := aString
]

{ #category : 'initialization' }
OPMcpTool >> initialize [

	super initialize.
	returnsContent := false
]

{ #category : 'accessing' }
OPMcpTool >> inputSchema: aDictionary [

	inputSchema := aDictionary
]

{ #category : 'accessing' }
OPMcpTool >> name [

	^ name
]

{ #category : 'accessing' }
OPMcpTool >> name: aString [

	name := aString
]

{ #category : 'accessing' }
OPMcpTool >> returnsContent [
	"True when the implementation answers MCP content blocks itself (e.g. an image) instead of data rendered as JSON text."

	^ returnsContent
]

{ #category : 'accessing' }
OPMcpTool >> returnsContent: aBoolean [

	returnsContent := aBoolean
]

{ #category : 'accessing' }
OPMcpTool >> selector [

	^ selector
]

{ #category : 'accessing' }
OPMcpTool >> selector: aSymbol [

	selector := aSymbol
]
