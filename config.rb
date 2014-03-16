# -*- coding: utf-8 -*-

class RTWacherConfig

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
