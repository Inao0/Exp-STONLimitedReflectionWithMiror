Class {
	#name : #MySTONRights,
	#superclass : #Object,
	#category : #MySTONPackage
}

{ #category : #'as yet unclassified' }
MySTONRights class >> recompile [

	self package methods do: [ :each | each recompile ]
]

{ #category : #'as yet unclassified' }
MySTONRights class >> requiredSelectors [
	
	^  {#instVarAt: . #instVarAt:put: }
]
