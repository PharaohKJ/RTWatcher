#! ruby -Ku
# -*- coding: utf-8 -*-

require 'bundler'
Bundler.require

require 'yaml'

require 'date'
require "rexml/document"
require 'uri'
require 'net/http'

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

TWEET_DB = "#{db_dir}tweetdb_#{userconf}.txt"

RT_DB = "#{db_dir}rtdb_#{userconf}.txt"


def expand_url(url)
  uri = url.kind_of?(URI) ? url : URI.parse(url)
  Net::HTTP.start(uri.host, uri.port) { |io|
    r = io.head(uri.path)
    r['Location'] || uri.to_s
  }
end

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

# DBオープン
db_version = "1.0"
rt_hash = Hash.new
type_rtrecord = Struct.new("RTRecord", :id, :rt_count, :rt_count_new, :rt_status)
begin
  db = open(RT_DB, "r")
  begin
    version = db.gets.chomp
    if ( version == db_version) then
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
type_config = Struct.new(
  "Config",
  :n_day,
  :kiriban1, :kiriban2, :kiriban3, :kiriban4, :kiriban5, :kiriban6,
  :kiriban2k, :kiriban3k, :kiriban4k, :kiriban5k, :kiriban6k, :kiriban7k, :kiriban8k, :kiriban9k, :kiriban10k,

  :head_1, :head_2, :head_3,:head_4,:head_5, :head_6,
  :head_2k, :head_3k, :head_4k,:head_5k,:head_6k, :head_7k,:head_8k, :head_9k, :head_10k,

  :footer_1, :footer_2, :footer_3, :footer_4, :footer_5, :footer_6,
  :footer_2k, :footer_3k, :footer_4k, :footer_5k, :footer_6k, :footer_7k, :footer_8k, :footer_9k, :footer_10k
)
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
    config.kiriban2k = fconfig.gets.chomp.to_i
    config.kiriban3k = fconfig.gets.chomp.to_i
    config.kiriban4k = fconfig.gets.chomp.to_i
    config.kiriban5k = fconfig.gets.chomp.to_i
    config.kiriban6k = fconfig.gets.chomp.to_i
    config.kiriban7k = fconfig.gets.chomp.to_i
    config.kiriban8k = fconfig.gets.chomp.to_i
    config.kiriban9k = fconfig.gets.chomp.to_i
    config.kiriban10k = fconfig.gets.chomp.to_i
    config.head_1 = fconfig.gets.chomp
    config.head_2 = fconfig.gets.chomp
    config.head_3 = fconfig.gets.chomp
    config.head_4 = fconfig.gets.chomp
    config.head_5 = fconfig.gets.chomp
    config.head_6 = fconfig.gets.chomp
    config.head_2k = fconfig.gets.chomp
    config.head_3k = fconfig.gets.chomp
    config.head_4k = fconfig.gets.chomp
    config.head_5k = fconfig.gets.chomp
    config.head_6k = fconfig.gets.chomp
    config.head_7k = fconfig.gets.chomp
    config.head_8k = fconfig.gets.chomp
    config.head_9k = fconfig.gets.chomp
    config.head_10k = fconfig.gets.chomp
    config.footer_1 = fconfig.gets.chomp
    config.footer_2 = fconfig.gets.chomp
    config.footer_3 = fconfig.gets.chomp
    config.footer_4 = fconfig.gets.chomp
    config.footer_5 = fconfig.gets.chomp
    config.footer_6 = fconfig.gets.chomp
    config.footer_2k = fconfig.gets.chomp
    config.footer_3k = fconfig.gets.chomp
    config.footer_4k = fconfig.gets.chomp
    config.footer_5k = fconfig.gets.chomp
    config.footer_6k = fconfig.gets.chomp
    config.footer_7k = fconfig.gets.chomp
    config.footer_8k = fconfig.gets.chomp
    config.footer_9k = fconfig.gets.chomp
    config.footer_10k = fconfig.gets.chomp
  ensure
    fconfig.close
  end
rescue
  puts "コンフィグロードエラー"
  exit
end

# statusからURLを取り出す
records.each do |record|
  sleep(1)

  # 調査対象URL抜き出し
  urlstrs = record.status.scan(/http.+html/)
  # livedoor経由のtwitterポストが短縮URLになってこうしないととれないことがある
  if ( urlstrs.length == 0)
    urlstrs = record.status.scan(/http:\/\/lb.to\/[a-zA-Z0-9]+/)
  end
  if ( urlstrs.length == 0)
    urlstrs = record.status.scan(/http:\/\/t.co\/[a-zA-Z0-9]+/)
  end

  # URLが抜き出せたら
  if ( urlstrs.length > 0)

    # puts "url: #{urlstrs}"

    # 短縮URL伸張
    targeturl=expand_url(urlstrs[0])
    expanded = targeturl.scan(/http:\/\/lb.to\/[a-zA-Z0-9]+/)
    if (expanded.length != 0)
      targeturl=expand_url(expanded[0])
    end

    # tweet数取得API準備
    urlstr = '/1/urls/count.json?url=' + targeturl

    Net::HTTP.version_1_2   # おまじない
    Net::HTTP.start('cdn.api.twitter.com', 80) do |http|

      #error が帰ってきたら3秒waitを入れて5度tryする
      response = nil
      5.times do
        response = http.get(urlstr, {'Connection' => 'Keep-Alive'})
        if ( response.code == '200') then
          break
        end
        sleep(3)
      end

      # それでもエラーだったらスキップする
      if response.code != '200' then
        puts "cannot call cdn.api.twitter.com! url = #{urlstr} code = #{response.code}"
        break
      end

      response_str = response.body.chomp
      p response_str
      parsed = JSON.parse(response_str)
      rt_count = parsed["count"].to_i

      if ( rt_hash[record.id] != nil) then
        rt_hash[record.id].rt_count_new = rt_count
      else
        b = type_rtrecord.new
        b.id = record.id
        b.rt_count = rt_count
        b.rt_count_new = rt_count
        b.rt_status = 0
        rt_hash[record.id] = b
      end
      
      twitstring = ""

      if (rt_count >= config.kiriban10k) then
         savedata = false
        if ( rt_hash[record.id] == nil) then savedata = true
        else
          if ( rt_hash[record.id].rt_status <= 14) then savedata = true end
        end
        if (savedata) then
          twitstring = "#{config.head_10k} #{record.status} #{config.footer_10k}"
          rt_hash[record.id].rt_status = 15
        end
      elsif (rt_count >= config.kiriban9k) then
         savedata = false
        if ( rt_hash[record.id] == nil) then savedata = true
        else
          if ( rt_hash[record.id].rt_status <= 13) then savedata = true end
        end
        if (savedata) then
          twitstring = "#{config.head_9k} #{record.status} #{config.footer_9k}"
          rt_hash[record.id].rt_status = 14
        end

      elsif (rt_count >= config.kiriban8k) then
                 savedata = false
        if ( rt_hash[record.id] == nil) then savedata = true
        else
          if ( rt_hash[record.id].rt_status <= 12) then savedata = true end
        end
        if (savedata) then
          twitstring = "#{config.head_8k} #{record.status} #{config.footer_8k}"
          rt_hash[record.id].rt_status = 13
        end

      elsif (rt_count >= config.kiriban7k) then
                 savedata = false
        if ( rt_hash[record.id] == nil) then savedata = true
        else
          if ( rt_hash[record.id].rt_status <= 11) then savedata = true end
        end
        if (savedata) then
          twitstring = "#{config.head_7k} #{record.status} #{config.footer_7k}"
          rt_hash[record.id].rt_status = 12
        end
      elsif (rt_count >= config.kiriban6k) then
                 savedata = false
        if ( rt_hash[record.id] == nil) then savedata = true
        else
          if ( rt_hash[record.id].rt_status <= 10) then savedata = true end
        end
        if (savedata) then
          twitstring = "#{config.head_6k} #{record.status} #{config.footer_6k}"
          rt_hash[record.id].rt_status = 11
        end
      elsif (rt_count >= config.kiriban5k) then
                 savedata = false
        if ( rt_hash[record.id] == nil) then savedata = true
        else
          if ( rt_hash[record.id].rt_status <= 9) then savedata = true end
        end
        if (savedata) then
          twitstring = "#{config.head_5k} #{record.status} #{config.footer_5k}"
          rt_hash[record.id].rt_status = 10
        end
      elsif (rt_count >= config.kiriban4k) then
                 savedata = false
        if ( rt_hash[record.id] == nil) then savedata = true
        else
          if ( rt_hash[record.id].rt_status <= 8) then savedata = true end
        end
        if (savedata) then
          twitstring = "#{config.head_4k} #{record.status} #{config.footer_4k}"
          rt_hash[record.id].rt_status = 9
        end
      elsif (rt_count >= config.kiriban3k) then
                 savedata = false
        if ( rt_hash[record.id] == nil) then savedata = true
        else
          if ( rt_hash[record.id].rt_status <= 7) then savedata = true end
        end
        if (savedata) then
          twitstring = "#{config.head_3k} #{record.status} #{config.footer_3k}"
          rt_hash[record.id].rt_status = 8
        end
      elsif (rt_count >= config.kiriban2k) then
                 savedata = false
        if ( rt_hash[record.id] == nil) then savedata = true
        else
          if ( rt_hash[record.id].rt_status <= 6) then savedata = true end
        end
        if (savedata) then
          twitstring = "#{config.head_2k} #{record.status} #{config.footer_2k}"
          rt_hash[record.id].rt_status = 7
        end

      elsif (rt_count >= config.kiriban6) then

         savedata = false
        if ( rt_hash[record.id] == nil) then savedata = true
        else
          if ( rt_hash[record.id].rt_status <= 5) then savedata = true end
        end
        if (savedata) then
          twitstring = "#{config.head_6} #{record.status} #{config.footer_6}"
          rt_hash[record.id].rt_status = 6
        end

      elsif (rt_count >= config.kiriban5) then

        if ( rt_hash[record.id] == nil) then
          twitstring = "#{config.head_5} #{record.status} #{config.footer_5}"

          rt_hash[record.id].rt_status = 5

        else

          if ( rt_hash[record.id].rt_status <= 4) then
            twitstring = "#{config.head_5} #{record.status} #{config.footer_5}"
            rt_hash[record.id].rt_status = 5

          end

        end

      elsif (rt_count >= config.kiriban4) then

        if ( rt_hash[record.id] == nil) then
          twitstring = "#{config.head_4} #{record.status} #{config.footer_4}"

          rt_hash[record.id].rt_status = 4

        else

          if ( rt_hash[record.id].rt_status <= 3) then
            twitstring = "#{config.head_4} #{record.status} #{config.footer_4}"
            rt_hash[record.id].rt_status = 4

          end

        end

      elsif (rt_count >= config.kiriban3) then

        if ( rt_hash[record.id] == nil) then
          twitstring = "#{config.head_3} #{record.status} #{config.footer_3}"

          rt_hash[record.id].rt_status = 3

        else

          if ( rt_hash[record.id].rt_status <= 2) then
            twitstring = "#{config.head_3} #{record.status} #{config.footer_3}"
            rt_hash[record.id].rt_status = 3

          end

        end

      elsif (rt_count >= config.kiriban2) then

        if ( rt_hash[record.id] == nil) then
          twitstring = "#{config.head_2} #{record.status} #{config.footer_2}"
          rt_hash[record.id].rt_status = 2

        else

          if ( rt_hash[record.id].rt_status <= 1) then
            twitstring = "#{config.head_2} #{record.status} #{config.footer_2}"
            rt_hash[record.id].rt_status = 2

          end

        end

      elsif (rt_count >=config.kiriban1) then

        if ( rt_hash[record.id] == nil) then
          #twitstring = "#{config.head_1} #{record.status} #{config.footer_1}"
          #rt_hash[record.id].rt_status = 1

        else

          if ( rt_hash[record.id].rt_status <= 0) then
          #  twitstring = "#{config.head_1} #{record.status} #{config.footer_1}"
          #  rt_hash[record.id].rt_status = 1

          end

        end

      end


      if (twitstring != "") then
        blog_title = /オレ的ゲーム速報＠刃 : /
        #puts twitstring.sub( blog_title, "")
        twitresult = access_token.post(
          'https://api.twitter.com/1.1/statuses/update.json',
          'status'=> twitstring.sub( blog_title, "")
        )
        puts twitresult.body
      end

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
