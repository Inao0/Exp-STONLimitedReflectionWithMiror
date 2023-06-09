Class {
	#name : #ReflectionMirror,
	#superclass : #Object,
	#instVars : [
		'target'
	],
	#category : #MyStonMirrorPackage
}

{ #category : #'instance creation' }
ReflectionMirror class >> on: anObject [
	1 haltIf: (anObject isKindOf: ReflectionMirror).
	^ self new target: anObject 
	
]

{ #category : #'as yet unclassified' }
ReflectionMirror >> mAllInstanceVariableNames [ 
	^ target class allInstVarNames 
]

{ #category : #reflectivity }
ReflectionMirror >> mInstVarNamed: aString [ 

	^ target class
		slotNamed: aString
		ifFound: [ :slot | slot read: target ]
		ifNone: [ InstanceVariableNotFound signalFor: aString asString ]
]

{ #category : #reflection }
ReflectionMirror >> mInstVarNamed: aString put: aValue [ 

	^ target class
		slotNamed: aString
		ifFound: [ :slot | slot write: aValue to: target ]
		ifNone: [ InstanceVariableNotFound signalFor: aString asString ]
]

{ #category : #accessing }
ReflectionMirror >> printOn: aStream [
	aStream << '/'.
	target printOn: aStream.
	aStream   << '/'.
]

{ #category : #accessing }
ReflectionMirror >> target [
	^ target
]

{ #category : #accessing }
ReflectionMirror >> target: anObject [ 
	target:= anObject.
]
