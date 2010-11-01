Dir[File.expand_path(File.join(File.dirname(__FILE__), 'gitpusshuten/**/*'))].each do |file|
  require file unless File.directory?(file)
end

module GitPusshuTen
end