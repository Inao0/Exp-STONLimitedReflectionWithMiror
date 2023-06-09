Class {
	#name : #ManifestWithReflectiveWhiteList,
	#superclass : #PackageManifest,
	#category : #'MySTONPackage-Manifest'
}

{ #category : #compiler }
ManifestWithReflectiveWhiteList class >> compiler [

	^ super compiler
		  addPlugin: (WhiteListPlugIn new whiteList: self requiredSelectors);
		  yourself
]

{ #category : #'as yet unclassified' }
ManifestWithReflectiveWhiteList class >> forbiddenSelectors [

	^ (self package methods flatCollect: [ :each | each messages ]) asSet 
		  select: [ :each | each beginsWith: 'bad_' ]
]

{ #category : #'as yet unclassified' }
ManifestWithReflectiveWhiteList class >> recompile [
<script>
	self package methods do: [ :each | each recompile ]
]

{ #category : #compiler }
ManifestWithReflectiveWhiteList class >> requiredSelectors [
	
	^  {}
]
