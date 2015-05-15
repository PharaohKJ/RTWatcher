#! ruby -Ku
# -*- coding: utf-8 -*-

require 'bundler'
Bundler.require

require_relative 'rtconfig.rb'
require_relative 'userconfig.rb'
require_relative 'tweetdb.rb'

require 'date'

## Create Initial Data
dir = File.expand_path(File.dirname($0))
config, cu, userconf = UserConfig.config(dir, ARGV[0])

db_dir = dir + '/db/'
ct = config['token']

## Configure twitter API
TARGET_USER = cu['target_user']
API_BASIC_URL = 'https://api.twitter.com/1.1/statuses/user_timeline'
API_RESULT_TYPE = 'json'
API_URL = "#{API_BASIC_URL}/#{TARGET_USER}.#{API_RESULT_TYPE}?count=200"
API_URL_AFTER = "#{API_BASIC_URL}/#{TARGET_USER}.#{API_RESULT_TYPE}?since_id="

TWEET_DB = "#{db_dir}tweetdb_#{userconf}.txt"

# 下準備
consumer = OAuth::Consumer.new(
  ct['consumer_key'],
  ct['consumer_secret'],
  site: 'https://twitter.com'
)
access_token = OAuth::AccessToken.new(
  consumer,
  cu['access_token'],
  cu['access_token_secret']
)

# DBオープン
tdb = TweetDb.new(TWEET_DB)

#configオープン
rtconfig = RtConfig.config(dir)

status_array = []
request = API_URL
if tdb.records.length != 0
  request = API_URL_AFTER + tdb.records.last[:id]
end

# puts request
response = access_token.get(request)

# puts response
JSON.parse(response.body).reverse_each do |status|
  begin
    # config['basic']['title']からの投稿のみを得る
    if status['source'].scan(/#{config['basic']['source']}/).length > 0
      puts "#{status['id']} :: #{status['created_at']} :: #{status['text']} :: #{status['source']}"
      status_array.push(status)
    end
  rescue
    STDERR.puts 'response parse error!'
    STDERR.puts $!
    STDERR.puts status
  end
end

status_array.each do |status|
  tdb.append(
    id: status['id'],
    date: status['created_at'],
    status: status['text']
  )
end

#データからn_dayより古いものを消去
tdb.clean_old(rtconfig['day'].to_i)

tdb.save(TWEET_DB)
