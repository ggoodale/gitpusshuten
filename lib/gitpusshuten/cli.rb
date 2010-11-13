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
      if @arguments.join(' ') =~ /((\w+) environment|(for|from|on|to) (\w+))/
        [$2, $3, $4].each do |match|
          unless match.nil?
            @environment = match.to_sym
            @arguments.delete(match)
          end
        end
        %w[to for from on environment].each do |argument|
          @arguments.delete(argument) if @arguments.include?(argument)
        end
      end

      ##
      # Extract Command
      @command = @arguments.shift
      @command = @command.underscore unless @command.nil?

    end

  end
end