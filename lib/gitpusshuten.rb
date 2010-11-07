require 'rubygems'
require 'bundler/setup' unless @ignore_bundler
require 'active_support/inflector'
require 'net/ssh'
require 'highline/import'
require 'rainbow'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'gitpusshuten/**/*'))].each do |file|
  if not File.directory?(file) and not file =~ /\/modules\/.+\/hooks\.rb/
    require file
  end
end

module GitPusshuTen
  VERSION = '0.0.1'
end