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
      # This is a flag, that, when set to true, will invoke the
      # potentially specified deployment hooks. When "perform_hooks"
      # is set to false, deployment hooks will not be invoked. This is the default
      # behavior. If hooks should be enabled for a specific command, invoke the
      # "perform_hooks!" command from within the "initialize" method of that particular command
      attr_accessor :perform_hooks
      alias :perform_hooks? :perform_hooks

      ##
      # This is used by the "help" command to display the
      # description of the command in the CLI
      def self.description(value = nil)
        if value.nil?
          @description
        else
          @description = value
        end
      end

      ##
      # This is used by the "help" command to display the
      # usage of the command in the CLI
      def self.usage(value = nil)
        if value.nil?
          @usage
        else
          @usage = value
        end
      end

      ##
      # This is used by the "help" command to display an
      # example of the command in the CLI
      def self.example(value = nil)
        if value.nil?
          @example
        else
          @example = value
        end
      end

      ##
      # Sets the "perform_hooks" flag to "true"
      def perform_hooks!
        @perform_hooks = true
      end

      ##
      # Displays the help screen for the current command
      def help
        command_object.display_usage(cli.command)
        exit
      end

      ##
      # Contains an instance of the command object
      def command_object
        @command_object ||= GitPusshuTen::Command.new(cli, configuration, hooks, environment)
      end

      ##
      # Git object wrapper
      def git
        @git ||= GitPusshuTen::Git.new
      end

      ##
      # The Pre-perform command
      # It should be invoked before the #perform! command
      def pre_perform!
        return unless perform_hooks?
        unless hooks.pre_hooks.any?
          GitPusshuTen::Log.message "No Pre-Deploy Hooks To Perform."
          return
        end
        
        ##
        # Connect to the remote environment and perform the pre deploy hooks
        environment.connect do |env|
          hooks.render_commands(hooks.pre_hooks).each do |name, commands|
            GitPusshuTen::Log.message("Performing Pre Deploy Hook: #{name}")
            puts env.exec!("cd '#{environment.application_root}'; #{commands}")
          end
        end
      end

      ##
      # The Post-perform command
      # It should be invoked after the #perform! command
      def post_perform!
        return unless perform_hooks?
        unless hooks.post_hooks.any?
          GitPusshuTen::Log.message "No Post-Deploy Hooks To Perform."
          return
        end
        
        ##
        # Connect to the remote environment and perform the post deploy hooks
        environment.connect do |env|
          hooks.render_commands(hooks.post_hooks).each do |name, commands|
            GitPusshuTen::Log.message("Performing Post Deploy Hook: #{name}")
            puts env.exec!("cd '#{environment.application_root}'; #{commands}")
          end
        end
      end

      def initialize(cli, configuration, hooks, environment)
        @cli           = cli
        @configuration = configuration
        @hooks         = hooks
        @environment   = environment
        @perform_hooks = false
      end

    end
  end
end