module GitPusshuTen
  module Commands
    class Base

      ##
      # Command-line Interface
      attr_accessor :cli

      ##
      # Configuration (Environment)
      attr_accessor :configuration

      ##
      # Stores the pre and post deploy hooks
      attr_accessor :hooks

      ##
      # Environment connection
      attr_accessor :environment
      
      ##
      # This is used by the "help" command to display the
      # description of the command in the CLI
      attr_accessor :description

      ##
      # This is used by the "help" command to display the
      # usage of the command in the CLI
      attr_accessor :usage

      ##
      # The Pre-perform command
      # It should be invoked before the #perform! command
      def pre_perform!
        unless hooks.pre_hooks.any?
          GitPusshuTen::Log.message "There are no pre-deploy hooks, skipping."
          return
        end

        ##
        # Connect to the remote environment and perform the pre deploy hooks        
        environment.connect do |env|
          hooks.render_commands(hooks.pre_hooks).each do |name, commands|
            GitPusshuTen::Log.message("Performing Pre Deploy Hook: #{name}")
            env.exec!("cd #{environment.application_root}; #{commands}")
          end
        end
      end

      ##
      # The Post-perform command
      # It should be invoked after the #perform! command
      def post_perform!
        unless hooks.post_hooks.any?
          GitPusshuTen::Log.message "There are no post-deploy hooks, skipping."
          return
        end
        
        ##
        # Connect to the remote environment and perform the post deploy hooks
        environment.connect do |env|
          hooks.render_commands(hooks.post_hooks).each do |name, commands|
            GitPusshuTen::Log.message("Performing Post Deploy Hook: #{name}")
            env.exec!("cd #{environment.application_root}; #{commands}")
          end
        end
      end

      def initialize(cli, configuration, hooks, environment)
        @cli           = cli
        @configuration = configuration
        @hooks         = hooks
        @environment   = environment
      end

    end
  end
end