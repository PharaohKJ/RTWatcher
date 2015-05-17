#! ruby -Ku
# -*- coding: utf-8 -*-

require 'bundler'
Bundler.require

require_relative 'rtconfig.rb'
require_relative 'userconfig.rb'
require_relative 'tweetdb.rb'
require_relative 'retweetdb.rb'

require 'date'
require 'rexml/document'
require 'uri'
require 'net/http'

## Create Initial Data
dir = File.expand_path(File.dirname($0))
config, cu, userconf = UserConfig.config(dir, ARGV[0])

db_dir = dir + '/db/'
ct = config['token']

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
tdb = TweetDb.new(TWEET_DB)

# DBオープン
rdb = RetweetDb.new(RT_DB)

#configオープン
rtconfig = RtConfig.config(dir)

# statusからURLを取り出す
tdb.records.each do |record|
  sleep(0.2)

  # 調査対象URL抜き出し
  urlstrs = record[:status].scan(/http.+html/)

  # livedoor経由のtwitterポストが短縮URLになってこうしないととれないことがある
  if urlstrs.length == 0
    urlstrs = record[:status].scan(%r{http://lb.to/[a-zA-Z0-9]+})
  end
  if urlstrs.length == 0
    urlstrs = record[:status].scan(%r{http://t.co/[a-zA-Z0-9]+})
  end

  # URLが抜き出せなかったら無視
  if urlstrs.length == 0
    # 抜き出せなかった
    STDERR.puts 'url not match!'
    STDERR.puts record[:status]
    next
  end

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
          STDOUT.puts "#{urlstr} failed.(code = #{response.code}) #{t} try."
          STDOUT.puts response
        end
        sleep(3)
      rescue
        STDERR.puts "#{urlstr} failed. throwed '#{$!}'"
      end
    end

    # それでもエラーだったらスキップする
    if response.code != '200'
      STDERR.puts "cannot call cdn.api.twitter.com! url = #{urlstr} code = #{response.code}"
      break
    end

    response_str = response.body.chomp
    puts "#{urlstr} count is #{response_str}."
    parsed = JSON.parse(response_str)
    rt_count = parsed["count"].to_i

    if rdb.rt[record[:id]].nil?
      puts "new record id:#{record[:id]} count: #{rt_count} status: 0"
      rdb.rt[record[:id]] = {
        id:           record[:id],
        rt_count:     rt_count,
        rt_count_new: rt_count,
        rt_status:    0
      }
    else
      print "update record id:#{record[:id]} "
      print "count: #{rt_count}(#{rdb.rt[record[:id]][:rt_count]}) "
      puts "status: #{rdb.rt[record[:id]][:rt_status]}"
      rdb.rt[record[:id]][:rt_count_new] = rt_count
    end

    twitstring = nil

    kiriban = rtconfig['kiriban'].sort do |v1, v2|
      v2['status'] <=> v1['status']
    end

    kiriban.each do |k|
      if rt_count >= k['count']
        if rdb.rt[record[:id]].nil? || rdb.rt[record[:id]][:rt_status] <= k['status'] - 1
          twitstring = "#{k['head']} #{record[:status]} #{k['foot']}"
          rdb.rt[record[:id]][:rt_status] = k['status']
        end
        break
      end
    end

    unless twitstring.nil?
      blog_title = /#{config['basic']['title']}/
      twitresult = access_token.post(
        'https://api.twitter.com/1.1/statuses/update.json',
        status: twitstring.sub(blog_title, '')
      )
      puts twitresult.body
    end
  end
end

rdb.save(RT_DB)
