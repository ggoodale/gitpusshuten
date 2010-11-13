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
      # Contains the invoked command
      attr_accessor :command

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
          @example ||= ""
          @example << "\n\s\s#{value}"
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
      # Local object wrapper
      def local
        @local ||= GitPusshuTen::Local.new
      end

      ##
      # Wrapper for the configuration object
      def c
        configuration
      end

      ##
      # Wrapper for the environment object
      def e
        environment
      end

      ##
      # Wrapper for coloring ANSI/CLI Green
      def g(value)
        value.to_s.color(:green)
      end

      ##
      # Wrapper for coloring ANSI/CLI Yellow
      def y(value)
        value.to_s.color(:yellow)
      end

      ##
      # Wrapper for coloring ANSI/CLI Red
      def r(value)
        value.to_s.color(:red)
      end

      ##
      # Helper method for prompting the user
      def yes?
        choose do |menu|
          menu.prompt = ''
          menu.choice('yes') { true  }
          menu.choice('no')  { false }
        end
      end

      ##
      # Shorthand for creating standard messages
      def standard(text)
        GitPusshuTen::Log.standard(text)
      end

      ##
      # Shorthand for creating normal messages
      def message(text)
        GitPusshuTen::Log.message(text)
      end

      ##
      # Shorthand for creating warning messages
      def warning(text)
        GitPusshuTen::Log.warning(text)
      end

      ##
      # Shorthand for creating error messages
      def error(text)
        GitPusshuTen::Log.error(text)
      end

      ##
      # Initialize a new command
      def initialize(cli, configuration, hooks, environment)
        @cli           = cli
        @configuration = configuration
        @hooks         = hooks
        @environment   = environment
        @perform_hooks = false
      end

      ##
      # Performs one of the commands inside a command class
      def perform!
        send("perform_#{command}!")
      end

      ##
      # Validates if the method that's about to be invoked actually exists
      def validate!
        if not respond_to?("perform_#{command}!")
          type = self.class.to_s.split("::").last.downcase
          error "Unknown #{y(type)} command: <#{r(command)}>"
          error "Run #{y("gitpusshuten help #{type}")} for a list #{y(type)} commands."
          exit
        end
      end

      ##
      # The Pre-perform command
      # It should be invoked before the #perform! command
      def pre_perform!
        return unless perform_hooks?
        unless hooks.pre_hooks.any?
          GitPusshuTen::Log.message "No pre deploy hooks to perform."
          return
        end
        
        ##
        # Connect to the remote environment and perform the pre deploy hooks
        hooks.render_commands(hooks.pre_hooks).each do |name, commands|
          GitPusshuTen::Log.message("Performing pre deploy hook: #{y(name)}")
          puts environment.execute_as_user("cd '#{e.app_dir}'; #{commands}")
        end
      end

      ##
      # The Post-perform command
      # It should be invoked after the #perform! command
      def post_perform!
        return unless perform_hooks?
        unless hooks.post_hooks.any?
          GitPusshuTen::Log.message "No post deploy hooks to perform."
          return
        end
        
        ##
        # Connect to the remote environment and perform the post deploy hooks
        hooks.render_commands(hooks.post_hooks).each do |name, commands|
          GitPusshuTen::Log.message("Performing post deploy hook: #{y(name)}")
          puts environment.execute_as_user("cd '#{e.app_dir}'; #{commands}")
        end
      end

      ##
      # Makes the user authenticate itself as root
      def prompt_for_root_password!
        e.execute_as_root('')
      end

      ##
      # Makes the user authenticate itself as a user
      def prompt_for_user_password!
        e.execute_as_user('')
      end

    end
  end
end