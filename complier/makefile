all: 
	java -cp antlr-3.5.3-complete.jar org.antlr.Tool myCompiler.g
	javac -cp antlr-3.5.3-complete.jar:. myCompilerLexer.java myCompilerParser.java myCompiler_test.java
	java -cp antlr-3.5.3-complete.jar:. myCompiler_test test3.c >test3.ll
	java -cp antlr-3.5.3-complete.jar:. myCompiler_test test2.c >test2.ll
	java -cp antlr-3.5.3-complete.jar:. myCompiler_test test.c >test.ll
	clang test.ll -o test.out
	clang test2.ll -o test2.out
	clang test3.ll -o test3.out
clean:
	rm *.out *.ll *.class *.tokens myCompilerLexer.java myCompilerParser.java
