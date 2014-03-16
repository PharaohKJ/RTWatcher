#! ruby -Ku
# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'
Bundler.require
require 'active_record'

require './db_init.rb'
require './config.rb'

require 'yaml'
require 'date'



## Read Config from yml
dir = File.expand_path(File.dirname($0))
config = YAML.load_file(dir + '/config.yml')
db_dir = dir + '/db/'
ct = config['token']

userconf = 'user'
if (!ARGV[0].nil?) then
  userconf = ARGV[0]
end

cu = config[userconf] 

## Configure twitter API
TARGET_USER = cu['target_user']
API_BASIC_URL = 'https://api.twitter.com/1.1/statuses/user_timeline'
API_RESULT_TYPE = 'json'
API_URL = "#{API_BASIC_URL}/#{TARGET_USER}.#{API_RESULT_TYPE}?count=200"
API_URL_AFTER = "#{API_BASIC_URL}/#{TARGET_USER}.#{API_RESULT_TYPE}?since_id="

TWEET_DB = "#{db_dir}tweetdb_#{userconf}.txt"


## Read Twitter DB
tdbf = TweetDBFile.new
tdbf.init( TWEET_DB )
p tdbf

## Read Config
config = RTWacherConfig.load('rtconf.txt')
p config

exit

## Initalize Twitter API with OAuth
consumer = OAuth::Consumer.new(
  ct['consumer_key'],
  ct['consumer_secret'],
  :site => 'https://twitter.com'
                               )
access_token = OAuth::AccessToken.new(
  consumer,
  cu['access_token'],
  cu['access_token_secret']
)


status_array = Array.new
request = API_URL
if records.length != 0 then
  request = API_URL_AFTER + records.last.id
end

# puts request
response = access_token.get(request)

# puts response
JSON.parse(response.body).reverse_each do |status|

  begin
    # livedoor Blogからの投稿のみを得る
    p status
    if status['source'].scan(/livedoor Blog/).length > 0 then
      puts "#{status['id']} :: #{status['created_at']} :: #{status['text']} :: #{status['source']}"
      status_array.push( status)
    end
  rescue
    STDERR.puts 'response parse error!'
    STDERR.puts $!
    STDERR.puts status
  end

end


status_array.each do |status|
  record = type_record.new
  record.id = status['id']
  record.date = status['created_at']
  record.status = status['text']
  records.push( record)
  TweetRecord.create(
    :tweet_id => record.id,
    :time => record.date,
    :status => record.status
  )
end

TweetRecord.find(:all).each{|i| p i}

#データからn_dayより古いものを消去
newrecords = Array.new
records.each do |record|
  parsedstr = Date.parse(record.date)
  date = parsedstr
  date += Rational(9, 24)
  date += config.n_day
  today = DateTime.now
  if ( today < date ) then
    newrecords.push( record)
  end
end

db = open(TWEET_DB, "w")
db.puts "1.0"
db.puts newrecords.size
newrecords.each do |record|
    #dbに書き込む
    db.puts(record.id)
    db.puts(record.date)
    db.puts(record.status)

end

db.close
