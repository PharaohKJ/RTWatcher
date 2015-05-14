#! ruby -Ku
# -*- coding: utf-8 -*-

require 'bundler'
Bundler.require

require_relative 'rtconfig.rb'
require_relative 'userconfig.rb'

require 'yaml'
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
db_version = "1.0"
records = []
type_record = Struct.new("DBRecord", :id, :date, :status)
begin
  db = open(TWEET_DB, "r")
  begin
    version = db.gets.chomp
    if version == db_version
      num_of_record = db.gets.chomp
      num_of_record.to_i.times do
        record = type_record.new
        record.id = db.gets.chomp
        record.date = db.gets.chomp
        record.status = db.gets.chomp
        records.push(record)
      end
    else
      #version not match!
    end
  rescue => result
    puts result
  ensure
    db.close
  end
rescue
  puts "DBリードエラー"
end

#configオープン
rtconfig = RtConfig.config(dir)

status_array = []
request = API_URL
if records.length != 0
  request = API_URL_AFTER + records.last.id
end

# puts request
response = access_token.get(request)

p config['basic']['source']

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
  record = type_record.new
  record.id = status['id']
  record.date = status['created_at']
  record.status = status['text']
  records.push(record)
end

#データからn_dayより古いものを消去
newrecords = []
records.each do |record|
  parsedstr = Date.parse(record.date)
  date = parsedstr
  date += Rational(9, 24)
  date += rtconfig['day'].to_i
  today = DateTime.now
  if today < date
    newrecords.push(record)
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
