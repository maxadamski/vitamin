Git-Package = {url: String, version: String}
Executable = {name file: String, depends: [Target]}
Target = Git-Package | Executable

build : (target: Target) -> Unit

