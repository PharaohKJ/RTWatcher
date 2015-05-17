# coding: utf-8

class RetweetDb
  attr_accessor :rt

  def initialize(path)
    db_version = "1.0"
    @rt = {}
    begin
      db = open(path, "r")
      begin
        version = db.gets.chomp
        if version == db_version
          num_of_record = db.gets.chomp
          num_of_record.to_i.times do
            id = db.gets.chomp
            @rt[id] = {
              id:           id,
              rt_count:     db.gets.chomp.to_i,
              rt_count_new: 0,
              rt_status:    db.gets.chomp.to_i
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

  def save(path)
    db = open(path, "w")
    db.puts "1.0"
    db.puts @rt.size
    @rt.each do |_id, value|
      #dbに書き込む
      db.puts(value[:id])
      db.puts(value[:rt_count_new])
      db.puts(value[:rt_status])
    end
    db.close
  end
end
