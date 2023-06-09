Class {
	#name : #LimitedReflectionMirror,
	#superclass : #ReflectionMirror,
	#instVars : [
		'hiddenVariables'
	],
	#classInstVars : [
		'hiddenVariablesPerClass'
	],
	#category : #MyStonMirrorPackage
}

{ #category : #initialization }
LimitedReflectionMirror class >> forClass: aClass hideInstanceVariableNamed: aString [

	(hiddenVariablesPerClass at: aClass ifAbsentPut: [ OrderedCollection new ] )
		add: aString 
]

{ #category : #initialization }
LimitedReflectionMirror class >> hiddenVariables [
	^hiddenVariablesPerClass 
]

{ #category : #initialization }
LimitedReflectionMirror class >> hiddenVariablesPerClasses: DictionnatyOfVariablesToHide [
	"Key should be the class and value de list of variable names to hide"
	hiddenVariablesPerClass :=  DictionnatyOfVariablesToHide 
]

{ #category : #initialization }
LimitedReflectionMirror class >> initialize [ 
	hiddenVariablesPerClass := Dictionary new
]

{ #category : #'instance creation' }
LimitedReflectionMirror class >> newMirorFactoryWithHiddenVariablesPerClass: variablesToHide [
	^ self newAnonymousSubclass 
		hiddenVariablesPerClasses: variablesToHide; 
		compile: 
			'hiddenVariables
			self shouldNotImplement';
		compile: 
			'hiddenVariablesPerClasses:
			self shouldNotImplement';
		compile: 
			'forClass: aClass hideInstanceVariableNamed: aString
			self shouldNotImplement';
		yourself 
]

{ #category : #accessing }
LimitedReflectionMirror >> initialize [ 
	super initialize.
	hiddenVariables := OrderedCollection new.
]

{ #category : #'as yet unclassified' }
LimitedReflectionMirror >> mAllInstanceVariableNames [ 

	^ target class allInstVarNames reject: [:each | hiddenVariables  includes: each].
]

{ #category : #'as yet unclassified' }
LimitedReflectionMirror >> mInstVarNamed: aString [ 
	(hiddenVariables includes: aString )
		ifTrue: [ ^ InstanceVariableNotFound signalFor: aString asString ].
	^ target class
		slotNamed: aString
		ifFound: [ :slot | slot read: target ]
		ifNone: [ InstanceVariableNotFound signalFor: aString asString ]
]

{ #category : #reflection }
LimitedReflectionMirror >> mInstVarNamed: aString put: aValue [ 

	(hiddenVariables includes: aString )
		ifTrue: [ ^ InstanceVariableNotFound signalFor: aString asString ].

	^ target class
		slotNamed: aString
		ifFound: [ :slot | slot write: aValue to: target ]
		ifNone: [ InstanceVariableNotFound signalFor: aString asString ]
]

{ #category : #accessing }
LimitedReflectionMirror >> target: anObject [ 
	target:= anObject.
	self updateHiddenVariables.
]

{ #category : #'as yet unclassified' }
LimitedReflectionMirror >> updateHiddenVariables [

	| hiddenVariablesPerClasses |
	hiddenVariablesPerClasses := self class hiddenVariables.
	hiddenVariablesPerClasses
		at: target class
		ifPresent: [ :variablesToHide | 
		hiddenVariables addAll: variablesToHide ].
	
	target class allSuperclassesDo: [ :aSuperclass | 
		hiddenVariablesPerClasses at: aSuperclass ifPresent: [ :variablesToHide | 
		hiddenVariables addAll: variablesToHide ]].
]
