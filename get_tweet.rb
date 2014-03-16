#! ruby -Ku
# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'
Bundler.require
require 'active_record'

require './db_init.rb'
require './config.rb'
require './twitter_api.rb'

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

## 
TWEET_DB = "#{db_dir}tweetdb_#{userconf}.txt"


## Read Twitter DB
tdb = TweetDBFile.new
tdb.init( TWEET_DB )
p tdb

## Read Config
config = RTWatcherConfig.load('rtconf.txt')
p config

## Initalize Twitter API with OAuth
twitter_api = RTWatcherTwitterAPI.new(
                                      ct['consumer_key'],
                                      ct['consumer_secret'],
                                      cu['access_token'],
                                      cu['access_token_secret'],
                                      cu['target_user']
                                      )

last_id = nil
if tdb.length != 0 then
  last_id = tdb.last.tweet_id
end

## Call twitter API
response = twitter_api.request( last_id)

## puts response
status_array = Array.new
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
