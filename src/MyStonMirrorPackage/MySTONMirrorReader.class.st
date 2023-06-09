Class {
	#name : #MySTONMirrorReader,
	#superclass : #Object,
	#instVars : [
		'readStream',
		'objects',
		'classes',
		'unresolvedReferences',
		'stringStream',
		'acceptUnknownClasses',
		'newLine',
		'convertNewLines',
		'mirrorFactory'
	],
	#category : #MyStonMirrorPackage
}

{ #category : #'instance creation' }
MySTONMirrorReader class >> on: readStream [
	^ self new
		on: readStream;
		yourself
]

{ #category : #'initialize-release' }
MySTONMirrorReader >> acceptUnknownClasses: boolean [
	acceptUnknownClasses := boolean
]

{ #category : #'initialize-release' }
MySTONMirrorReader >> allowComplexMapKeys: boolean [
	"This is a no-op, this used to be an option, but it is now always enabled"
]

{ #category : #testing }
MySTONMirrorReader >> atEnd [
	^ readStream atEnd
]

{ #category : #'initialize-release' }
MySTONMirrorReader >> close [
	readStream ifNotNil: [
		readStream close.
		readStream := nil ]
]

{ #category : #private }
MySTONMirrorReader >> consumeWhitespace [
	"Strip whitespaces from the input stream."

	[ readStream atEnd not and: [ readStream peek isSeparator ] ]
		whileTrue: [ readStream next ]
]

{ #category : #'initialize-release' }
MySTONMirrorReader >> convertNewLines: boolean [
	"When true, any newline CR, LF or CRLF read unescaped inside strings or symbols 
	will be converted to the newline convention chosen, see #newLine:
	The default is false, not doing any conversions."
	
	convertNewLines := boolean
]

{ #category : #'error handling' }
MySTONMirrorReader >> error: aString [
	| streamPosition |
	"Remain compatible with streams that don't understand #position"
	streamPosition := [ readStream position ]
		on: MessageNotUnderstood do: [ nil ].
	^ STONReaderError signal: aString streamPosition: streamPosition
]

{ #category : #private }
MySTONMirrorReader >> expectChar: character [
	"Expect character and consume input and optional whitespace at the end,
	 throw an error otherwise."

	(self matchChar: character)
		ifFalse: [ self error: character asString, ' expected' ]
]

{ #category : #'initialize-release' }
MySTONMirrorReader >> initialize [
	super initialize.
	objects := IdentityDictionary new.
	classes := IdentityDictionary new.
	acceptUnknownClasses := convertNewLines := false.
	newLine := String cr.
	unresolvedReferences := 0
]

{ #category : #private }
MySTONMirrorReader >> isClassChar: char [
	^ char isAlphaNumeric or: [ char = $_ ]
]

{ #category : #private }
MySTONMirrorReader >> isClassStartChar: char [
	^ char isLetter and: [ char isUppercase ]
]

{ #category : #private }
MySTONMirrorReader >> isSimpleSymbolChar: char [
	^char isLetter or: ['0123456789-_./' includes: char]
]

{ #category : #private }
MySTONMirrorReader >> lookupClass: name [
	"name is a symbol at this point"
	Smalltalk globals 
		at: name 
		ifPresent: [ :class | ^ class ].
	"note that classes is an identity dictionary"
	^ classes 
		at: name 
		ifAbsentPut: [
			Object allSubclasses 
				detect: [ :class | class isMeta not and: [ class stonName = name ]  ]
				ifNone: [ NotFound signalFor: name ] ]
]

{ #category : #private }
MySTONMirrorReader >> match: string do: block [
	"Try to read and consume string and execute block if successful.
	Else do nothing (but do not back up)"

	(string allSatisfy: [ :each | readStream peekFor: each ])
		ifTrue: [ 
			self consumeWhitespace.
			block value ]
]

{ #category : #private }
MySTONMirrorReader >> matchChar: character [
	"Tries to match character, consume input and 
	answer true if successful and consumes whitespace at the end."

	^ (readStream peekFor: character)
		ifTrue: [ 
			self consumeWhitespace.
			true ]
		ifFalse: [ false ]
]

{ #category : #accessing }
MySTONMirrorReader >> mirrorFactory: aMirrorFactory [

	mirrorFactory := aMirrorFactory
]

{ #category : #'initialize-release' }
MySTONMirrorReader >> newLine: string [
	"Set the newline convention to be used when converting newlines, see #convertNewLines"
	
	newLine := string
]

{ #category : #private }
MySTONMirrorReader >> newReference [
	| index reference |
	index := objects size + 1.
	reference := STONReference index: index.
	objects at: index put: reference.
	^ reference
]

{ #category : #public }
MySTONMirrorReader >> next [
	| object |
	self consumeWhitespace.
	object := self parseValue.
	unresolvedReferences > 0
		ifTrue: [ self processSubObjectsOf: object ].
	unresolvedReferences = 0
		ifFalse: [ self error: 'Inconsistent reference resolution' ].
	^ object
]

{ #category : #'initialize-release' }
MySTONMirrorReader >> on: aReadStream [
	readStream := aReadStream
]

{ #category : #'initialize-release' }
MySTONMirrorReader >> optimizeForLargeStructures [
	self class environment
		at: #FLLargeIdentityDictionary
		ifPresent: [ :identityDictionaryClass | objects := identityDictionaryClass new ]
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseCharacter [
	| char |
	^ (char := readStream next) = $\
		ifTrue: [ self parseEscapedCharacter ]
		ifFalse: [ char ]
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseCharacterConvertingNewLinesOn: writeStream [
	| char |
	(char := readStream next) = $\
		ifTrue: [ writeStream nextPut: self parseEscapedCharacter ]
		ifFalse: [ 
			char = Character lf 
				ifTrue: [ writeStream nextPutAll: newLine ]
				ifFalse: [ 
					char = Character cr 
						ifTrue: [ 
							readStream peekFor: Character lf.
							writeStream nextPutAll: newLine ]
						ifFalse: [ writeStream nextPut: char ] ] ]
]

{ #category : #private }
MySTONMirrorReader >> parseCharacterHex [
	| value codePoint |
	value := self parseCharacterHex4Value.
	(value < 16rD800 or: [ value > 16rDBFF ])
		ifTrue: [ codePoint := value ]
		ifFalse: [ | leadSurrogate trailSurrogate |
			"Characters not in the Basic Multilingual Plane are encoded as a UTF-16 surrogate pair"
			"See https://tools.ietf.org/html/rfc7159#section-7"
			leadSurrogate := value.
			trailSurrogate := self parseTrailingSurrogateHexEscape.
			codePoint := (leadSurrogate - 16rD800) * 16r400 + (trailSurrogate - 16rDC00).
			codePoint := 16r10000 + codePoint ].
	^ Character codePoint: codePoint
]

{ #category : #private }
MySTONMirrorReader >> parseCharacterHex4Value [
	| value |
	value := self parseCharacterHexDigit.
	3 timesRepeat: [ 
		value := (value << 4) + self parseCharacterHexDigit ].
	^ value
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseCharacterHexDigit [
	| digit |
	readStream atEnd ifFalse: [ 
		digit := readStream next asInteger.
		(digit between: "$0" 48 and: "$9" 57)
			ifTrue: [ ^ digit - 48 ].
		(digit between: "$A" 65 and: "$F" 70)
			ifTrue: [ ^ digit - 55 ].
		(digit between: "$a" 97 and: "$f" 102)
			ifTrue: [ ^ digit - 87 ] ].
	self error: 'hex-digit expected'
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseClass [
	| className |
	className := self stringStreamContents: [ :stream |
		[ readStream atEnd not and: [ self isClassChar: readStream peek ] ] whileTrue: [ 
			stream nextPut: readStream next ] ].
	self consumeWhitespace.
	^ self lookupClass: className asSymbol
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseConstantDo: block [
	"Parse and consume either true|false|nil|null and execute block 
	or else do nothing (but do not back up).
	Hand written implementation to avoid the use of #position:"
	
	(readStream peek = $t)
		ifTrue: [
			^ self match: 'true' do: [ block value: true ] ].
	(readStream peek = $f)
		ifTrue: [
			^ self match: 'false' do: [ block value: false ] ].
	(readStream peek = $n)
		ifTrue: [
			readStream next.
			(readStream peek = $i)
				ifTrue: [
					self match: 'il' do: [ block value: nil ] ].
			(readStream peek = $u)
				ifTrue: [
					self match: 'ull' do: [ block value: nil ] ] ]
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseEscapedCharacter [
	| char |
	char := readStream next.
	(#($' $" $/ $\) includes: char)
		ifTrue: [ ^ char ].
	char = $b
		ifTrue: [ ^ Character backspace ].
	char = $f
		ifTrue: [ ^ Character newPage ].
	char = $n
		ifTrue: [ ^ Character lf ].
	char = $r
		ifTrue: [ ^ Character cr ].
	char = $t
		ifTrue: [ ^ Character tab ].
	char = $u
		ifTrue: [ ^ self parseCharacterHex ].
	self error: 'invalid escape character \' , (String with: char).
	^ char
]

{ #category : #parsing }
MySTONMirrorReader >> parseList [
	| reference array |
	reference := self newReference.
	array := STON listClass streamContents: [ :stream |
		self parseListDo: [ :each | stream nextPut: each ] ].
	self setReference: reference to: array.
	^ array
]

{ #category : #parsing }
MySTONMirrorReader >> parseListDo: block [
	| index |
	self expectChar: $[.
	(self matchChar: $]) ifTrue: [ ^ self ]. "short cut for empty lists"
	index := 1.
	[ readStream atEnd ] whileFalse: [
		block cull: self parseValue cull: index.
		(self matchChar: $]) ifTrue: [ ^ self ].
		index := index + 1.
		self expectChar: $, ].
	self error: 'end of list expected'
]

{ #category : #parsing }
MySTONMirrorReader >> parseListSingleton [
	| value |
	value := nil.
	self parseListDo: [ :each :index |
		index = 1 ifTrue: [ value := each ] ].
	^ value
]

{ #category : #parsing }
MySTONMirrorReader >> parseMap [
	| map |
	map := STON mapClass new.
	self storeReference: map.
	self parseMapDo: [ :key :value |
		map at: key put: value ].
	^ map
]

{ #category : #parsing }
MySTONMirrorReader >> parseMapDo: block [
	self expectChar: ${.
	(self matchChar: $}) ifTrue: [ ^ self ]. "short cut for empty maps"
	[ readStream atEnd ] whileFalse: [ | name value |
		name := self parseSimpleValue.
		self expectChar: $:.
		value := self parseValue.
		block value: name value: value.
		"The above is a more efficient way to say 'self parseValue' and using the returned association"
		(self matchChar: $}) ifTrue: [ ^ self ].
		self expectChar: $, ].
	self error: 'end of map expected'
]

{ #category : #parsing }
MySTONMirrorReader >> parseMapOrListRepresentation [
	"Parse either a map or list to be used as a representation, not considering it as a referenceable object"
	readStream atEnd 
		ifFalse: [ 
			readStream peek = ${
				ifTrue: [ | map |
					map := STON mapClass new.
					self parseMapDo: [ :key :value |
						map at: key put: value ].
					^ map ].
			readStream peek = $[
				ifTrue: [ 
					^ STON listClass streamContents: [ :stream |
						self parseListDo: [ :each | stream nextPut: each ] ] ] ].
	self error: 'invalid input'
]

{ #category : #parsing }
MySTONMirrorReader >> parseNamedInstVarsFor: anObject [
	self parseMapDo: [ :instVarName :value |
		(ReflectionMirror on: anObject) mInstVarNamed: instVarName asString put: value ]
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseNumber [
	| negated number |
	negated := readStream peekFor: $-.
	number := self parseNumberInteger.
	(readStream peekFor: $/)
		ifTrue: [ 
			number := Fraction numerator: number denominator: self parseNumberInteger.
			(readStream peekFor: $s)
				ifTrue: [ number := ScaledDecimal newFromNumber: number scale: self parseNumberInteger ] ]
		ifFalse: [ 
			(readStream peekFor: $.)
				ifTrue: [ number := number + self parseNumberFraction ].
			((readStream peekFor: $e) or: [ readStream peekFor: $E ])
				ifTrue: [ number := number * self parseNumberExponent ] ].
	negated
		ifTrue: [ number := number negated ].
	self consumeWhitespace.
	^ number
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseNumberExponent [
	| number negated |
	number := 0.
	(negated := readStream peekFor: $-)
		ifFalse: [ readStream peekFor: $+ ].
	[ readStream atEnd not and: [ readStream peek isDigit ] ]
		whileTrue: [ number := 10 * number + readStream next digitValue ].
	negated
		ifTrue: [ number := number negated ].
	^ 10 raisedTo: number
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseNumberFraction [
	| number power |
	number := 0.
	power := 1.0.
	[ readStream atEnd not and: [ readStream peek isDigit ] ] whileTrue: [
		number := 10 * number + readStream next digitValue.
		power := power * 10.0 ].
	^ number / power
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseNumberInteger [
	| number |
	number := 0.
	[ readStream atEnd not and: [ readStream peek isDigit ] ] whileTrue: [ 
		number := 10 * number + readStream next digitValue ].
	^ number
]

{ #category : #parsing }
MySTONMirrorReader >> parseObject [
	| targetClass reference object |
	[
		reference := self newReference.
		targetClass := self parseClass.
		object := targetClass fromSton: self .
		self setReference: reference to: object ]
		on: NotFound 
		do: [ :notFound |
			acceptUnknownClasses 
				ifTrue: [ 
					object := STON mapClass new.
					self storeReference: object.
					self parseMapDo: [ :key :value |
						object at: key put: value ].
					object at: STON classNameKey put: notFound object ]
				ifFalse: [ self error: 'Cannot resolve class named ', notFound object printString ] ].
	^ object
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseReference [
	| index |
	self expectChar: $@.
	index := self parseNumberInteger.
	self consumeWhitespace.
	unresolvedReferences := unresolvedReferences + 1.
	^ STONReference index: index
]

{ #category : #parsing }
MySTONMirrorReader >> parseSimpleValue [
	| char |
	readStream atEnd ifFalse: [ 
		(self isClassStartChar: (char := readStream peek)) 
			ifTrue: [ ^ self parseObject ].
		char = ${
			ifTrue: [ ^ self parseMap ].
		char = $[
			ifTrue: [ ^ self parseList ].
		(char = $' or: [ char = $" ])
			ifTrue: [ ^ self parseString ].
		char = $#
			ifTrue: [ ^ self parseSymbol ].
		char = $@
			ifTrue: [ ^ self parseReference ].
		(char = $- or: [ char isDigit ])
			ifTrue: [ ^ self parseNumber ].
		self parseConstantDo: [ :value | ^ value ] ].
	self error: 'invalid input'
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseString [
	1 halt.
	^ self parseStringInternal
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseStringInternal [
	| result delimiter |
	delimiter := readStream next.
	(delimiter = $' or: [ delimiter = $" ])
		ifFalse: [ self error: ''' or " expected' ].
	result := self
		stringStreamContents: [ :stream | 
			convertNewLines
				ifTrue: [ 
					[ readStream atEnd or: [ readStream peek = delimiter ] ] 
						whileFalse: [ self parseCharacterConvertingNewLinesOn: stream ] ]
				ifFalse: [ 
					[ readStream atEnd or: [ readStream peek = delimiter ] ] 
						whileFalse: [ stream nextPut: self parseCharacter ] ] ].
	self expectChar: delimiter.
	^ result
]

{ #category : #'parsing-internal' }
MySTONMirrorReader >> parseSymbol [
	| string |
	self expectChar: $#.
	readStream peek = $'
		ifTrue: [ ^ self parseStringInternal asSymbol ].
	string := self stringStreamContents: [ :stream |
		[ readStream atEnd not and: [ self isSimpleSymbolChar: readStream peek ] ] whileTrue: [
			stream nextPut: readStream next ] ].
	string isEmpty
		ifFalse: [ 
			self consumeWhitespace.
			^ string asSymbol ].
	self error: 'unexpected input'
]

{ #category : #private }
MySTONMirrorReader >> parseTrailingSurrogateHexEscape [
	(readStream next = $\ and: [ readStream next = $u ])
		ifTrue: [ ^ self parseCharacterHex4Value ]
		ifFalse: [ self error: 'trailing surrogate hex escape expected' ]
]

{ #category : #parsing }
MySTONMirrorReader >> parseValue [
	| value |
	value := self parseSimpleValue.
	^ (self matchChar: $:)
		ifTrue: [ STON associationClass key: value value: self parseValue ]
		ifFalse: [ value ]
]

{ #category : #private }
MySTONMirrorReader >> processSubObjectsOf: object [
	| unresolvedReferencesCount |
	unresolvedReferencesCount := unresolvedReferences.
	object stonProcessSubObjects: [ :each | 
		each isStonReference
			ifTrue: [ self resolveReference: each ]
			ifFalse: [ 
				each stonContainSubObjects
					ifTrue: [ self processSubObjectsOf: each ]
					ifFalse: [ each ] ] ].
	unresolvedReferencesCount > unresolvedReferences
		ifTrue: [ object stonPostReferenceResolution ].
	^ object
]

{ #category : #'initialize-release' }
MySTONMirrorReader >> reset [
	unresolvedReferences := 0.
	objects removeAll
]

{ #category : #private }
MySTONMirrorReader >> resolveReference: reference [
	unresolvedReferences := unresolvedReferences - 1.
	^ self resolveReferenceIndex: reference index
]

{ #category : #private }
MySTONMirrorReader >> resolveReferenceIndex: index [
	^ objects at: index
]

{ #category : #private }
MySTONMirrorReader >> setReference: reference to: object [
	objects at: reference index put: object
]

{ #category : #private }
MySTONMirrorReader >> storeReference: object [
	| index |
	index := objects size + 1.
	objects at: index put: object.
	^ index
]

{ #category : #private }
MySTONMirrorReader >> stringStreamContents: block [
	stringStream ifNil: [ 
		stringStream := (String new: 32) writeStream ].
	stringStream reset.
	block value: stringStream.
	^ stringStream contents
]