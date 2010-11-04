module GitPusshuTen
  class Log

    ##
    # Displays a regular message
    def self.message(message)
      puts "[message] ".color(:green) + message
    end

    ##
    # Displays a warning message
    def self.warning(message)
      puts "[warning] ".color(:yellow) + message
    end

    ##
    # Displays an error message
    def self.error(message)
      puts "[error] ".color(:red) + message
    end

  end
end