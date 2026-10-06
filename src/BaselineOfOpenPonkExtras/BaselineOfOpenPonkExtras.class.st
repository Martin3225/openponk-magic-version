"
Metacello baseline for local extensions of OpenPonk (OpenPonk-Extras).
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
			package: 'OpenPonk-Extras-Tests' with: [ spec requires: #( 'OpenPonk-Extras' ) ].
		spec
			group: 'default' with: #( 'OpenPonk-Extras' );
			group: 'all' with: #( 'OpenPonk-Extras' 'OpenPonk-Extras-Tests' ) ]
]
