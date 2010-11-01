module GitPusshuTen
  class Log
    def self.message(message)
      puts "[message] ".color(:green) + message
    end
    
    def self.warn(message)
      puts "[warning] ".color(:yellow) + message
    end
    
    def self.error(message)
      puts "[error] ".color(:red) + message
    end    
  end
end