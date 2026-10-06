"
Configuration applied by tools/build.sh to the development image after loading the extensions.
"
Class {
	#name : 'OPExtrasSetup',
	#superclass : 'Object',
	#category : 'OpenPonk-MCP',
	#package : 'OpenPonk-MCP'
}

{ #category : 'building' }
OPExtrasSetup class >> afterBuild [
	"The MCP server starts whenever this image starts (not now: the image is saved and quit right after)."

	OPMcpServer autoStart: true
]
