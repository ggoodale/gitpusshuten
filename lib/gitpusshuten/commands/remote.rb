module GitPusshuTen
  module Commands
    class Remote < GitPusshuTen::Commands::Base
      description "Performs a command on the remote server for the specified environment from the application root."
      usage       "remote command on <environment> '<command>'"
      example     "heavenly remote command on staging 'cat log/production.log'                # Invokes 'cat log/production.log' in the staging environment."
      example     "heavenly remote command on production 'mkdir tmp; touch tmp/restart.txt'   # Invokes 'mkdir tmp; touch tmp/restart.txt' in the production environment."

      attr_accessor :command_to_execute

      def initialize(*objects)
        super
                
        @command = cli.arguments.shift if cli.arguments.any?
        @command_to_execute = cli.arguments.join(' ') if cli.arguments.any?
        
        help if command.nil? or command_to_execute.nil? or e.name.nil?
      end

      ##
      # Performs a unix command on the remote server
      def perform_command!
        message "Performing command on #{y(c.application)} (#{y(e.name)}) at #{y(c.ip)}!"
        puts e.execute_as_user("cd #{e.app_dir}; #{command_to_execute}")
      end

    end
  end
end