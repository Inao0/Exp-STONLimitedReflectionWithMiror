Class {
	#name : #LimitedReflectionMirrorReadingUnknownVariableNoCrash,
	#superclass : #LimitedReflectionMirror,
	#category : #MyStonPackage
}

{ #category : #reflection }
LimitedReflectionMirrorReadingUnknownVariableNoCrash >> mInstVarNamed: aString put: aValue [ 

	(hiddenVariables includes: aString )
		ifTrue: [ ^ nil ].

	^ target class
		slotNamed: aString
		ifFound: [ :slot | slot write: aValue to: target ]

]
