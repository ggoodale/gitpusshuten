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
      # If the arguments match the following pattern, it'll simply assign
      # the variables accordingly
      if @arguments.join(' ') =~ /(\w+\-?\w*) (.+) (for|to|from|on) (\w+)(.+)?/
        @command     = $1
        @arguments   = $2.split(' ')
        @environment = $4.to_sym
        
        ##
        # Allows for more arguments to be passed in after the regular expression.
        # These arguments will be converted to an array and apended to the "@arguments" array
        if $5.is_a?(String)
          @arguments += $5.split(' ')
        end
        return
      end
      
      ##
      # If the arguments match the following pattern, it'll assign the variables
      # and check check if the last argument in the array of @arguments is a
      # "for", "to", "from" or "on" string value, and deletes it if it is
      if @arguments.join(' ') =~ /(\w+\-?\w*) (.+) (\w+) environment/
        @command     = $1
        @arguments   = $2.split(' ')
        @environment = $3.to_sym
        
        ##
        # Clean up any for/to/from/on if it's the last argument
        # of the @arguments array since that'd be part of the CLI
        if %w[for to from on].include? @arguments.last
           @arguments.delete_at(@arguments.count - 1)
        end
        return
      end
      
      ##
      # If no arguments are specified it'll just take the command,
      # set the arguments to an empty array and set the environment
      if @arguments.join(' ') =~ /(\w+\-?\w*) (.+) (\w+)$/
        @command     = $1
        @arguments   = []
        @environment = $2.to_sym
        return
      end
      
      ##
      # If only a command and one or more arguments are specified,
      # without an environment, the regular expression below is matched.
      if @arguments.join(' ') =~ /(\w+\-?\w*) (.+)$/
        @command     = $1
        @arguments   = $2.split(' ')
        return
      end
    end

  end
end