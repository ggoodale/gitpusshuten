require 'rubygems'

begin
  require 'rainbow'
  require 'active_support/inflector'
rescue LoadError
  puts "Please ensure that you have the following gems installed:\n\n"
  %w[activesupport rainbow].each do |gem|
    puts "\s\s* #{gem}"
  end
end

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'gitpusshuten/**/*'))].each do |file|
  require file unless File.directory?(file)
end

module GitPusshuTen
end