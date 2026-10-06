"
Metacello baseline for local extensions of OpenPonk: OpenPonk-Extras (editor improvements), OpenPonk-Extras-OntoUML (OntoUML assistant: model check, stereotype and generalization set menus, adding elements from text) and OpenPonk-MCP (MCP server).
"
Class {
	#name : 'BaselineOfOpenPonkExtras',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfOpenPonkExtras',
	#package : 'BaselineOfOpenPonkExtras'
}

{ #category : 'baselines' }
BaselineOfOpenPonkExtras >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec
			package: 'OpenPonk-Extras';
			package: 'OpenPonk-Extras-Tests' with: [ spec requires: #( 'OpenPonk-Extras' ) ];
			package: 'OpenPonk-Extras-OntoUML' with: [ spec requires: #( 'OpenPonk-Extras' ) ];
			package: 'OpenPonk-Extras-OntoUML-Tests' with: [ spec requires: #( 'OpenPonk-Extras-OntoUML' ) ];
			package: 'OpenPonk-MCP' with: [ spec requires: #( 'OpenPonk-Extras' 'OpenPonk-Extras-OntoUML' ) ];
			package: 'OpenPonk-MCP-Tests' with: [ spec requires: #( 'OpenPonk-MCP' ) ].
		spec
			group: 'default' with: #( 'OpenPonk-Extras' 'OpenPonk-Extras-OntoUML' 'OpenPonk-MCP' );
			group: 'all'
			with: #( 'OpenPonk-Extras' 'OpenPonk-Extras-Tests' 'OpenPonk-Extras-OntoUML' 'OpenPonk-Extras-OntoUML-Tests'
				   'OpenPonk-MCP' 'OpenPonk-MCP-Tests' ) ]
]
