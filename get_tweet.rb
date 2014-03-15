#! ruby -Ku
# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'
Bundler.require
require 'active_record'

require 'yaml'
require 'date'

## Create Initial Data
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

def find_id( id, records)
  records.each do |record|
    if (record.id == id) then
      return record
    end
  end

end

# 下準備
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

# DBオープン
db_version = "1.0"
records = Array.new
type_record = Struct.new("DBRecord", :id, :date, :status)
begin
  db = open(TWEET_DB, "r")
  begin
    version = db.gets.chomp
    if ( version == db_version) then
      num_of_record = db.gets.chomp
      num_of_record.to_i.times do
        record = type_record.new
        record.id = db.gets.chomp
        record.date = db.gets.chomp
        record.status = db.gets.chomp
        records.push( record)
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
type_config = Struct.new( "Config",
  :n_day,
  :kiriban1, :kiriban2, :kiriban3,:kiriban4, :kiriban5,:kiriban6,
  :head_1, :head_2, :head_3,:head_4,:head_5, :head_6,
  :footer_1, :footer_2, :footer_3, :footer_4, :footer_5, :footer_6)
config = type_config.new
begin
  fconfig = open("rtconf.txt", "r")
  begin

    header = fconfig.gets.chomp
    if ( header != "RTConfig v1") then
      raise
    end

    config.n_day = fconfig.gets.chomp.to_i
    config.kiriban1 = fconfig.gets.chomp.to_i
    config.kiriban2 = fconfig.gets.chomp.to_i
    config.kiriban3 = fconfig.gets.chomp.to_i
    config.kiriban4 = fconfig.gets.chomp.to_i
    config.kiriban5 = fconfig.gets.chomp.to_i
    config.kiriban6 = fconfig.gets.chomp.to_i
    config.head_1 = fconfig.gets.chomp
    config.head_2 = fconfig.gets.chomp
    config.head_3 = fconfig.gets.chomp
    config.head_4 = fconfig.gets.chomp
    config.head_5 = fconfig.gets.chomp
    config.head_6 = fconfig.gets.chomp
    config.footer_1 = fconfig.gets.chomp
    config.footer_2 = fconfig.gets.chomp
    config.footer_3 = fconfig.gets.chomp
    config.footer_4 = fconfig.gets.chomp
    config.footer_5 = fconfig.gets.chomp
    config.footer_6 = fconfig.gets.chomp
  ensure
    fconfig.close
  end
rescue
  puts "コンフィグロードエラー"
  exit
end

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

ActiveRecord::VERSION::STRING

ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ":memory:"
)

class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table :tweet_records do |t|
      t.string :tweet_id, :null => false
      t.text :status, :null => false
      t.date :time, :null => false
      t.timestamp
    end
  end

  def self.down
    drop_table :users
  end
end

InitialSchema.migrate(:up)


class TweetRecord < ActiveRecord::Base
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
