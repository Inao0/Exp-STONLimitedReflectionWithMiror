Class {
	#name : #STONTestUser4,
	#superclass : #STONTestUser,
	#instVars : [
		'friends'
	],
	#category : #MyStonMirrorPackage
}

{ #category : #accessing }
STONTestUser4 >> addFriend: aSTONTestUser [ 
	friends add: aSTONTestUser.
]

{ #category : #accessing }
STONTestUser4 >> friends [

	^ friends
]

{ #category : #accessing }
STONTestUser4 >> initialize [ 
	super initialize.
	friends := OrderedCollection new.
]
