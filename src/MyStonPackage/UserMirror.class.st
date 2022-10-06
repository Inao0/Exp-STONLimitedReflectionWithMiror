Class {
	#name : #UserMirror,
	#superclass : #BoilerplateMirror,
	#category : #MyStonPackage
}

{ #category : #'as yet unclassified' }
UserMirror >> mAllInstanceVariableNames [ 
	
	^ #(username password enabled)
]

{ #category : #'as yet unclassified' }
UserMirror >> mInstVarNamed: aString [ 

	#username = aString ifTrue: [ ^ target username ].
	#password = aString ifTrue: [ ^ target password ].
	#enabled = aString ifTrue: [ ^ target enabled ].
	
	self error: 'aaahhh'
]

{ #category : #'as yet unclassified' }
UserMirror >> mInstVarNamed: aString put: aValue [ 

	#username = aString ifTrue: [ ^ target username: aValue ].
	#password = aString ifTrue: [ ^ target password: aValue ].
	#enabled = aString ifTrue: [ ^ target enabled: aValue ].
	
	self error: 'aaahhh'
]

{ #category : #accessing }
UserMirror >> target: anObject [ 
	
	target := anObject
]
