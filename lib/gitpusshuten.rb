require 'rubygems'
require 'bundler/setup'
require 'active_support/inflector'
require 'net/ssh'
require 'highline/import'
require 'rainbow'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'gitpusshuten/**/*'))].each do |file|
  require file unless File.directory?(file)
end

module GitPusshuTen
  VERSION = '0.0.1'
end