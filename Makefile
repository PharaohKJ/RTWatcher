help:
	grep '^##' Makefile


## run 実行
run:
	ruby get_tweet.rb
	ruby check_do_rt.rb

## debug TEST_USERで実行する
debug:
	ruby get_tweet.rb $(TEST_USER)
	ruby check_do_rt.rb $(TEST_USER)

docker_build:
	docker build -t rtwatcher --no-cache ./
