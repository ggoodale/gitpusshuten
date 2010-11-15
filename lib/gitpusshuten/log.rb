# encoding: utf-8
module GitPusshuTen
  class Log

    ##
    # Displays a regular message without prefix
    def self.standard(message)
      puts message
      to_file message
    end
    
    ##
    # Displays a regular message
    def self.message(message)
      message = "[message] ".color(:green) + message
      puts message
      to_file message
    end

    ##
    # Displays a warning message
    def self.warning(message)
      message = "[warning] ".color(:yellow) + message
      puts message
      to_file message
    end

    ##
    # Displays an error message
    def self.error(message)
      message = "[error] ".color(:red) + message
      puts message
      to_file message
    end

    ##
    # Silently logs messages
    def self.silent(message)
      to_file message
    end

    ##
    # Logs the message to the log file
    def self.to_file(message)
      return unless message.is_a?(String)
      
      ##
      # Don't log if we're not working within the Gitpusshuten directory
      if File.directory?(gitpusshuten_dir)
        
        ##
        # Create the log directory if it doesn't exist
        if not File.directory?(log_dir)
          %x[mkdir -p '#{log_dir}']
        end
        
        ##
        # Remove all ANSI coloring codes for clean logging
        message.gsub!(/\[\d+m/, '')
        
        ##
        # Log the message to the file (append)
        File.open(File.join(log_dir, 'gitpusshuten.log'), 'a') do |file|
          file << "\n#{Time.now.strftime("[%m/%d/%Y %H:%M:%S]")} #{message}"
        end
        
      end
    end

    ##
    # Returns the Gitpusshuten directory path
    def self.gitpusshuten_dir
      File.join(Dir.pwd, '.gitpusshuten')
    end

    ##
    # Returns the Gitpusshuten log directory path
    def self.log_dir
      File.join(gitpusshuten_dir, 'log')
    end

  end
end