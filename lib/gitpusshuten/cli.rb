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
      # Extract Command
      @command = @arguments.shift.underscore

      ##
      # Extract Environment
      if @arguments.join(' ') =~ /(to (\w+)|(\w+) environment|for (\w+))/
        [$2, $3, $4].each do |match|
          unless match.nil?
            @environment = match.to_sym
            @arguments.delete(match)
          end
        end
        %w[to for environment].each do |argument|
          @arguments.delete(argument) if @arguments.include?(argument)
        end
      end

    end

  end
end