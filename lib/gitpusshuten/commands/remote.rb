module GitPusshuTen
  module Commands
    class Remote < GitPusshuTen::Commands::Base
      description "Performs a command on the remote server for the specified environment from the application root."
      usage       "remote for <environment> '<command>'"
      example     "remote for staging 'cat log/production.log'"
      example     "remote for production 'mkdir tmp; touch tmp/restart.txt'"

      ##
      # Setup specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the Remote command
      def initialize(*objects)
        super
        
        help if cli.arguments.empty? or e.name.nil?
        
        @command = cli.arguments.join(' ')
      end

      ##
      # Performs the Delete command
      def perform!
        GitPusshuTen::Log.message "Performing command on #{y(c.application)} (#{y(e.name)}) at #{y(c.ip)}!"
        puts environment.execute_as_user("cd #{e.app_dir}; #{command}")
      end

    end
  end
end