姓名: 林靖軒
學號: 408410002
系級: 資工三
執行環境: Ubuntu 20.04
                  antlr-3.5.3-complete.jar

執行方式: 在Ubuntu的terminal中輸入make後會對myComplier.g進行編譯產生myComplierParser.java、myComplierLexer.java 跟myComplier.tokens三個檔案，之後會編譯所有java檔案，之後分別執行test.c、test2.c、test3.c三個測試檔並產生test.ll、test2.ll、test3.ll，之後clang filename.ll來產生test.out、test2.out、test3.out，由使用者在treminal決定用lli直接執行或是執行用clang編譯出的.out檔(llc編譯出的.s檔無法編成out檔，因為有printf()，需用clang filename.ll 來產生執行檔)來產生結果。在terminal中輸入make clean後會將產生的檔案都清除掉(包含*.class、myComplierLexer.java、myComplierParser.java、myComplier.tokens、*.ll、*out)

檔案: 
	myComplier.g: 定義C_subset跟rules的g檔
	testParser.java: 執行的java程式
	test.c: 測試int、printf (一個int)、if_else的功能
	test2.c: 測試int、printf(兩個int)、if_else後有if_else會不會出錯
	test3.c:  測試int、printf (一個int)、printf(沒有int，只有文字)、if_else裡包含if_else會不會出錯
	test.out、test2.out、test3.out: 執行檔
	makefile: 編譯程式
	readme: project說明
	