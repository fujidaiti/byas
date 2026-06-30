# Generate Dart data classes from the API spec.
.PHONY: gen-dart
gen-dart:
	openapi-generator generate -i api.yaml -g dart -o dart_binding --global-property=models,modelTests=false,modelDocs=false
