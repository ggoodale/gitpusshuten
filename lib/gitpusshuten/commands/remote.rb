module GitPusshuTen
  module Commands
    class Remote < GitPusshuTen::Commands::Base
      description "Performs a command on the remote server for the specified environment from the application root."
      usage       "remote '<command>' for <environment>"
      example     "remote 'cat log/production.log' for staging"
      example     "remote 'mkdir tmp; touch tmp/restart.txt' for production"

      ##
      # Setup specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the Delete command
      def initialize(*objects)
        super
        
        help if cli.arguments.empty? or environment.name.nil?
        
        @command = cli.arguments.join(' ')
      end

      ##
      # Performs the Delete command
      def perform!
        GitPusshuTen::Log.message "Performing command on #{app_name} (#{environment_name}) at #{ip_addr}!"
        puts environment.execute(command)
      end

    end
  end
end