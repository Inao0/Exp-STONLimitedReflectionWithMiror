Class {
	#name : #LimitedReflectionMirrorReadingUnknownVariableNoCrash,
	#superclass : #LimitedReflectionMirror,
	#category : #MyStonMirrorPackage
}

{ #category : #reflection }
LimitedReflectionMirrorReadingUnknownVariableNoCrash >> mInstVarNamed: aString put: aValue [ 

1halt.
	(hiddenVariables includes: aString )
		ifTrue: [ ^ nil ].

	^ target class
		slotNamed: aString
		ifFound: [ :slot | slot write: aValue to: target ]

]
