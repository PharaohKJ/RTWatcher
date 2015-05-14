# coding: utf-8
require 'yaml'

class RtConfig
  attr_reader :rtconfig

  def initialize(base_path)
    #configオープン
    @rtconfig = YAML.load_file(base_path + '/rtconf.yml')
    unless rtconfig['version'] == 'RTConfig v1'
      raise
    end
  rescue
    puts $!
    puts "コンフィグロードエラー"
    exit
  end

  def self.config(base_path = './')
    RtConfig.new(base_path).rtconfig
  end
end
