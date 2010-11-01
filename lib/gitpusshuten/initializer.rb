module GitPusshuTen
  class Initializer
    
    def initialize(*args)
      if not File.exist?(configuration_file)
        puts "Could not locate the GitPusshuTen configuration file in #{configuration_file}"
        exit
      end
      
      GitPusshuTen::Configuration.new(args).parse!(configuration_file)
    end
    
    def configuration_file
      File.expand_path(File.join(Dir.pwd, '.gitpusshuten', 'config.rb'))
    end
    
  end
end