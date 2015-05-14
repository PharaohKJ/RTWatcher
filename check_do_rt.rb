#! ruby -Ku
# -*- coding: utf-8 -*-

require 'bundler'
Bundler.require

require 'yaml'

require 'date'
require 'rexml/document'
require 'uri'
require 'net/http'

## Create Initial Data
dir = File.expand_path(File.dirname($0))
config = YAML.load_file(dir + '/config.yml')
db_dir = dir + '/db/'
ct = config['token']

userconf =  ARGV[0] || 'user'
cu = config[userconf]

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

TWEET_DB = "#{db_dir}tweetdb_#{userconf}.txt"

RT_DB = "#{db_dir}rtdb_#{userconf}.txt"

def expand_url(url)
  uri = url.is_a?(URI) ? url : URI.parse(url)
  out = ''
  begin
    Net::HTTP.start(uri.host, uri.port) do |io|
      r = io.head(uri.path)
      out = r['Location'] || uri.to_s
    end
  rescue => ex
    puts ex.to_s
  rescue Timeout::Error => ex
    retry
  end
  out
end

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

# DBオープン
db_version = "1.0"
rt_hash = {}
type_rtrecord = Struct.new(
  'RTRecord',
  :id,
  :rt_count,
  :rt_count_new,
  :rt_status
)
begin
  db = open(RT_DB, "r")
  begin
    version = db.gets.chomp
    if version == db_version
      num_of_record = db.gets.chomp
      num_of_record.to_i.times do
        record = type_rtrecord.new
        record.id = db.gets.chomp
        record.rt_count = db.gets.chomp.to_i
        record.rt_count_new = 0
        record.rt_status = db.gets.chomp.to_i
        rt_hash[record.id] = record
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
begin
  config = YAML.load_file('rtconf.yml')
  unless config['version'] == 'RTConfig v1'
    raise
  end
rescue
  puts $!
  puts "コンフィグロードエラー"
  exit
end

# statusからURLを取り出す
records.each do |record|
  sleep(0.2)
  # STDERR.puts Time.now

  # 調査対象URL抜き出し
  urlstrs = record.status.scan(/http.+html/)
  # livedoor経由のtwitterポストが短縮URLになってこうしないととれないことがある
  if urlstrs.length == 0
    urlstrs = record.status.scan(%r{http://lb.to/[a-zA-Z0-9]+})
  end
  if urlstrs.length == 0
    urlstrs = record.status.scan(%r{http://t.co/[a-zA-Z0-9]+})
  end

  # URLが抜き出せなかったら無視
  if urlstrs.length == 0
    # 抜き出せなかった
    STDERR.puts 'url not match!'
    STDERR.puts record.status
    next
  end

  # puts "url: #{urlstrs}"

  # 短縮URL伸張
  targeturl = expand_url(urlstrs[0])
  expanded = targeturl.scan(%r{http://lb.to/[a-zA-Z0-9]+})
  if (expanded.length != 0)
    targeturl = expand_url(expanded[0])
  end

  # tweet数取得API準備
  urlstr = '/1/urls/count.json?url=' + URI.encode(targeturl)

  Net::HTTP.version_1_2   # おまじない
  Net::HTTP.start('cdn.api.twitter.com', 443, use_ssl: true) do |http|

    #error が帰ってきたら3秒waitを入れて5度tryする
    response = nil
    5.times do |t|
      begin
        response = http.get(urlstr, 'Connection' => 'Keep-Alive')
        if response.code == '200'
          break
        else
          STDOUT.puts t
          STDOUT.puts response
        end
        sleep(3)
      rescue
        STDERR.puts $!
        STDERR.puts urlstr
      end
    end

    # それでもエラーだったらスキップする
    if response.code != '200'
      STDERR.puts "cannot call cdn.api.twitter.com! url = #{urlstr} code = #{response.code}"
      break
    end

    response_str = response.body.chomp
    p response_str
    parsed = JSON.parse(response_str)
    rt_count = parsed["count"].to_i

    unless rt_hash[record.id].nil?
      rt_hash[record.id].rt_count_new = rt_count
    else
      b = type_rtrecord.new
      b.id = record.id
      b.rt_count = rt_count
      b.rt_count_new = rt_count
      b.rt_status = 0
      rt_hash[record.id] = b
    end

    twitstring = nil

    kiriban = config['kiriban'].sort do |v1, v2|
      v2['status'] <=> v1['status']
    end

    kiriban.each do |k|
      if rt_count >= k['count']
        if rt_hash[record.id].nil? || rt_hash[record.id].rt_status <= k['status'] - 1
          twitstring = "#{k['head']} #{record.status} #{k['foot']}"
          rt_hash[record.id].rt_status = k['status']
        end
        break
      end
    end

    unless twitstring.nil?
      blog_title = /#{config['title']}/
      #puts twitstring.sub( blog_title, "")
      twitresult = access_token.post(
        'https://api.twitter.com/1.1/statuses/update.json',
        status: twitstring.sub(blog_title, '')
      )
      puts twitresult.body
    end
  end
end

db = open(RT_DB, "w")
db.puts "1.0"
db.puts rt_hash.size
#type_rtrecord = Struct.new("RTRecord", :id, :rt_count, :rt_count_new, :rt_status)
rt_hash.each do |id, value|
  #dbに書き込む
  db.puts(value.id)
  db.puts(value.rt_count_new)
  db.puts(value.rt_status)
end
