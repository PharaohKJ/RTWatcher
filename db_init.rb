#! ruby -Ku
# -*- coding: utf-8 -*-

require 'date'

class TweetDBAccessor

  def self.get
    # default
    return TweetDBFile.new
  end

end

class TweetDB

  def initialize
    @records = Array.new
    @type_record = Struct.new('TweetRecord', :tweet_id, :time, :status)
  end

  def new_record( id, time, status)
    return @type_record.new( id, time, status)
  end

  def append(id, time, status)
    @records.push( self.new_record( id, time, status))
  end

end


class TweetDBFile < TweetDB
  DB_VERSION = '1.0'

  def init(path)
    self.load(path)
  end

  def load(path)
    begin
      db = open(path, 'r')
      begin
        version = db.gets.chomp
        if ( version == DB_VERSION) then
          num_of_record = db.gets.chomp
          num_of_record.to_i.times do
            self.append(
                        db.gets.chomp,
                        db.gets.chomp,
                        db.gets.chomp
                        )
          end
        else
          return 'version not match!'
        end
      rescue => result
        puts result
      ensure
        db.close
      end
    rescue
      return 'DB READ ERROR'
    end
    return 'NO ERROR'
  end

  # fileに保存
  def save(path)
    db = open(path, "w")
    db.puts "1.0"
    db.puts @records.size
    @records.each do |record|
      #dbに書き込む
      db.puts(record.tweet_id)
      db.puts(record.time)
      db.puts(record.status)
    end
    db.close
  end

  def last
    return @records.last
  end

  def length
    return @records.size
  end

  def clean_old( n_day )
    #データからn_dayより古いものを消去
    newrecords = Array.new
    @records.each do |record|
      parsedstr = Date.parse(record.time)
      date = parsedstr
      date += Rational(9, 24)
      date += n_day
      today = DateTime.now
      if ( today < date ) then
        newrecords.push( record)
      end
    end
    @records = newrecords
  end

end

class TweetDBSQLite < TweetDB

  def init
  end

  def save
  end

end

