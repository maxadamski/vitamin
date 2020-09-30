Target = [|
	git-package : (url: String, version: String)
	executable : (name file: String, depands: [Target])
|]

build : (target: Target) -> Unit

