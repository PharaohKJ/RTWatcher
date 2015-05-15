# coding: utf-8
require 'yaml'

class UserConfig
  attr_reader :cfg

  def initialize(base_path)
    #configオープン
    @cfg = YAML.load_file(base_path + '/config.yml')
  end

  def self.config(base_path = './', userconf)
    userconf = 'user' if userconf.nil?
    out = UserConfig.new(base_path).cfg
    return out, out[userconf], userconf
  end
end
