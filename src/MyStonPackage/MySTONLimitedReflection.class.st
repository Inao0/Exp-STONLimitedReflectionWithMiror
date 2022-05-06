Class {
	#name : #MySTONLimitedReflection,
	#superclass : #TestCase,
	#category : #MyStonPackage
}

{ #category : #tests }
MySTONLimitedReflection >> serialize: anObject withMirrorFactory: aMirrorFactory [
	^ String streamContents: [ :stream |
		MySTONWriter new 
			on: stream;
			mirrorFactory: aMirrorFactory;
			nextPut: anObject ]
]

{ #category : #tests }
MySTONLimitedReflection >> testHiddenInstanceVarShouldRaiseError [

	| user hiddenVariables mirror |
	hiddenVariables := Dictionary newFrom:
		                   { (STONTestUser -> { 'password'. 'enabled' }) }.

	(user := STONTestUser new)
		username: 'john@foo.com';
		password: 'secret1'.

	mirror := (LimitedReflectionMirror 
		           newMirorFactoryWithHiddenVariablesPerClass:
		           hiddenVariables) on: user.
		
	self shouldFail: (mirror mInstVarNamed: 'password')
]

{ #category : #tests }
MySTONLimitedReflection >> testUser [
	| user userWithFriends|
	(user := STONTestUser new)
		username: 'john@foo.com';
		password: 'secret1'.
	(userWithFriends := STONTestUser4 new)
		username: 'john@bar.com';
		password: 'secret2';
		addFriend: user.
	self 
		assert: (self serialize: userWithFriends withMirrorFactory: ReflectionMirror)
		equals:'TestUser{#username:''john@bar.com'',#password:''secret2'',#enabled:true,#friends:OrderedCollection[TestUser{#username:''john@foo.com'',#password:''secret1'',#enabled:true}]}'
]

{ #category : #tests }
MySTONLimitedReflection >> testUserWithHiddenPassword [
	| user hiddenVariables|
	
	hiddenVariables := Dictionary newFrom: {STONTestUser -> {'password'}}.
	
	(user := STONTestUser new)
		username: 'john@foo.com';
		password: 'secret1'.
		
	self 
		assert: (self serialize: user withMirrorFactory: 
			(LimitedReflectionMirror newMirorFactoryWithHiddenVariablesPerClass: hiddenVariables) )
		equals:'TestUser{#username:''john@foo.com'',#enabled:true}'
]

{ #category : #tests }
MySTONLimitedReflection >> testUserWithHiddenPasswordAndEnabled [

	| user hiddenVariables |
	hiddenVariables := Dictionary newFrom:
		                   { STONTestUser -> { 'password' . 'enabled' }. 	}.

	(user := STONTestUser new)
		username: 'john@foo.com';
		password: 'secret1'.

	self
		assert: (self
				 serialize: user
				 withMirrorFactory:
					 (LimitedReflectionMirror 
						  newMirorFactoryWithHiddenVariablesPerClass: hiddenVariables))
		equals: 'TestUser{#username:''john@foo.com''}'
]

{ #category : #tests }
MySTONLimitedReflection >> testUserWithHiddenVariablesInheritance [

	| user hiddenVariables userWithFriends |
	hiddenVariables := Dictionary newFrom: { 
			                   (STONTestUser -> { 'password' }).
			                   (STONTestUser4 -> { 'enabled' }).
			                   (STONTestUser5 -> { 'friends' }) }.

	(user := STONTestUser new)
		username: 'john@foo.com';
		password: 'secret1'.


	(userWithFriends := STONTestUser4 new)
		username: 'john@bar.com';
		password: 'secret2';
		addFriend: user.

	self
		assert: (self
				 serialize: userWithFriends
				 withMirrorFactory:
					 (LimitedReflectionMirror 
						  newMirorFactoryWithHiddenVariablesPerClass: hiddenVariables))
		equals:
		'TestUser{#username:''john@bar.com'',#friends:OrderedCollection[TestUser{#username:''john@foo.com'',#enabled:true}]}'
]
