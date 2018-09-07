ANTLR = java -jar ~/.local/lib/antlr-4.7.1-complete.jar
GRUN = java org.antlr.v4.gui.TestRig

.PHONY: parser test

parser:
	$(ANTLR) -Dlanguage=Python3 -o vitamin/parser VitaminC.g4
	touch vitamin/parser/__init__.py

test:
	python3 vitamin/tests/expression_test.py

main: parser
	python3 vitamin.py sample/main.vc

syntax_debug:
	$(ANTLR) -Dlanguage=Java -o tmp VitaminC.g4
	javac -g tmp/*.java
	CLASSPATH=tmp:"$$CLASSPATH" $(GRUN) VitaminC program -gui


