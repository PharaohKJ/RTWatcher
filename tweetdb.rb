# coding: utf-8

class TweetDb
  attr_accessor :records

  def initialize(path)
    db_version = "1.0"
    @records = []
    begin
      db = open(path, "r")
      begin
        version = db.gets.chomp
        if version == db_version
          num_of_record = db.gets.chomp
          num_of_record.to_i.times do
            @records << {
              id: db.gets.chomp,
              date: db.gets.chomp,
              status: db.gets.chomp
            }
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
  end

  def clean_old(day)
    newrecords = []
    @records.each do |record|
      parsedstr = Date.parse(record[:date])
      date = parsedstr
      date += Rational(9, 24)
      date += day.to_i
      today = DateTime.now
      if today < date
        newrecords.push(record)
      end
    end
    @records = newrecords
  end

  def save(path)
    db = open(path, "w")
    db.puts "1.0"
    db.puts @records.size
    @records.each do |record|
      #dbに書き込む
      db.puts(record[:id])
      db.puts(record[:date])
      db.puts(record[:status])
    end
    db.close
  end

  def append(id: nil, date: nil, status: nil)
    @records << {
      id: id,
      date: date,
      status: status
    }
  end
end
