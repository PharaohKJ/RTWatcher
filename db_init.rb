#! ruby -Ku
# -*- coding: utf-8 -*-

class TweetDB

  def initialize( type )
    case type
    when :file then
    when :sqlite then
    end
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
  def save
    db = open(TWEET_DB, "w")
    db.puts "1.0"
    db.puts @records.size
    @records.each do |record|
      #dbに書き込む
      db.puts(record.tweet_id)
      db.puts(record.time)
      db.puts(record.status)
    end
  end

end

class TweetDBSQLite < TweetDB

  def init
  end

  def save
  end

end

class ConfigDB

  HEADER = 'RTConfig v1'

  def self.load(fname)
    type_config = Struct.new( "Config",
                               :n_day,
                               :kiriban1, :kiriban2, :kiriban3,:kiriban4, :kiriban5,:kiriban6,
                               :head_1, :head_2, :head_3,:head_4,:head_5, :head_6,
                               :footer_1, :footer_2, :footer_3, :footer_4, :footer_5, :footer_6
                               )
    config = type_config.new

    begin

      fconfig = open(fname, "r")
      begin

        header = fconfig.gets.chomp
        if ( header != HEADER) then
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
      p 'config load error'
      #return 'config load error'
    end
    return config 
  end
end
