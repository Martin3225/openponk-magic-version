"
I read multiplicities written by the user: '1', '0..1', '0..*', '*', '1...3' (three dots work as two) and real numbers such as '0.5..2.5' or '0,5..2,5' (decimal comma). Bounds are answered as numbers (an integral real becomes an Integer) and the unlimited upper bound as '*', the way OpenPonk stores them in the literals of a multiplicity element.

	OPMultiplicityParser boundsFrom: '0,5...2'. ""#(0.5 2)""
	OPMultiplicityParser write: '1..*' to: aProperty.
"
Class {
	#name : 'OPMultiplicityParser',
	#superclass : 'Object',
	#category : 'OpenPonk-Extras-Multiplicity',
	#package : 'OpenPonk-Extras',
	#tag : 'Multiplicity'
}

{ #category : 'parsing' }
OPMultiplicityParser class >> boundsFrom: aString [
	"Answer { lower. upper }; signal OPInvalidMultiplicity for anything else."

	| text separator lower upper |
	text := (aString ifNil: [ '' ]) asString trimBoth copyReplaceAll: ',' with: '.'.
	text = '*' ifTrue: [ ^ #( 0 '*' ) ].
	(text matchesRegex: self numberPattern) ifTrue: [
		lower := self numberFrom: text.
		^ { lower. lower } ].
	(text matchesRegex: self numberPattern , '[ ]*\.\.\.?[ ]*(\*|' , self numberPattern , ')')
		ifFalse: [ self invalid: aString because: 'expected e.g. 1, 0..1, 0..*, 1...3 or 0.5..2.5' ].
	separator := text indexOfSubCollection: '..'.
	lower := self numberFrom: (text copyFrom: 1 to: separator - 1) trimBoth.
	upper := (text copyFrom: separator + 2 to: text size) trimBoth.
	(upper beginsWith: '.') ifTrue: [ upper := upper allButFirst trimBoth ].
	upper := upper = '*'
		         ifTrue: [ '*' ]
		         ifFalse: [ self numberFrom: upper ].
	(upper ~= '*' and: [ lower > upper ]) ifTrue: [
		self invalid: aString because: 'the lower bound is greater than the upper bound' ].
	^ { lower. upper }
]

{ #category : 'private' }
OPMultiplicityParser class >> invalid: aString because: aReason [

	OPInvalidMultiplicity signal:
		'Invalid multiplicity "' , aString asString , '": ' , aReason
]

{ #category : 'private' }
OPMultiplicityParser class >> numberFrom: aString [

	| number |
	number := Number readFrom: aString.
	number < 0 ifTrue: [ self invalid: aString because: 'bounds cannot be negative' ].
	^ (number isInteger not and: [ number fractionPart = 0 ])
		  ifTrue: [ number truncated ]
		  ifFalse: [ number ]
]

{ #category : 'private' }
OPMultiplicityParser class >> numberPattern [

	^ '-?[0-9]+(\.[0-9]+)?'
]

{ #category : 'writing' }
OPMultiplicityParser class >> write: aString to: aMultiplicityElement [
	"Set the bounds of aMultiplicityElement (a UML property); invalid text is reported to the user and changes nothing."

	| bounds |
	bounds := [ self boundsFrom: aString ]
		          on: OPInvalidMultiplicity
		          do: [ :error |
			          InformativeNotification signal: error messageText.
			          ^ self ].
	aMultiplicityElement lowerValue ifNil: [
		aMultiplicityElement lowerValue: OPUMLLiteralInteger new ].
	aMultiplicityElement upperValue ifNil: [
		aMultiplicityElement upperValue: OPUMLLiteralUnlimitedNatural new ].
	aMultiplicityElement lowerValue value: bounds first.
	aMultiplicityElement upperValue value: bounds second
]
