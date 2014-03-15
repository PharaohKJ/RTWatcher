
help:
	grep '^##' Makefile


## run 実行
run:
	bundle exec ruby get_tweet.rb
	bundle exec ruby check_do_rt.rb

## debug TEST_USERで実行する
debug:
	bundle exec ruby get_tweet.rb $(TEST_USER)
#	bundle exec ruby check_do_rt.rb $(TEST_USER)

bi:
	bundle install --path vendor/bundler
