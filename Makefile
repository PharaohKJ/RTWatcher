
help:
	grep '^##' Makefile


## run 実行
run:


## debug jin115watcherで実行する
debug:
	ruby get_tweet.rb $(TEST_USER)
	ruby check_do_rt.rb $(TEST_USER)
