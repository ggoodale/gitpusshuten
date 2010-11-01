module GitPusshuTen
  class Log
    def self.log(message)
      puts "[message] #{message}"
    end
    
    def self.warn(message)
      puts "[warning] #{message}"
    end
    
    def self.error(message)
      puts "[error] #{message}"
    end    
  end
end