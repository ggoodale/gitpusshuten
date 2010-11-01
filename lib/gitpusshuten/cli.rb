module GitPusshuTen
  class CLI
    
    ##
    # Arguments
    attr_accessor :arguments    
    
    ##
    # Environment
    attr_accessor :environment
    
    ##
    # Command
    attr_accessor :command
    
    def initialize(*args)
      
      ##
      # Clean up arguments
      @arguments = args.flatten.uniq.compact.map(&:strip)
      
      ##
      # Extract Environment
      if @arguments.join(' ') =~ /(to (\w+)|(\w+) environment|for (\w+))/
        [$2, $3, $4].each do |match|
          @environment = match.to_sym unless match.nil?
        end
      end
      
      ##
      # Extract Command
      @command = @arguments.first.strip
      
    end
    
  end
end