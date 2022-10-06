Class {
	#name : #BoilerplateMirror,
	#superclass : #Object,
	#instVars : [
		'target'
	],
	#category : #MyStonPackage
}

{ #category : #'instance creation' }
BoilerplateMirror class >> on: anObject [ 
	
	^ anObject boilerplateMirrorClass new
		target: anObject;
		yourself
]

{ #category : #'as yet unclassified' }
BoilerplateMirror >> mAllInstanceVariableNames [ 
	
	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
BoilerplateMirror >> mInstVarNamed: aString [ 

	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
BoilerplateMirror >> mInstVarNamed: aString put: aValue [ 

	self subclassResponsibility 
]
