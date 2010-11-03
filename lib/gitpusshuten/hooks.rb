module GitPusshuTen
  class Hooks

    ##
    # Contains the environment on the remote server name which
    # is extracted from the selected configuration in the configuration file
    attr_accessor :environment

    ##
    # Contains an array of GitPusshuTen::Hook objects for the current environment
    attr_accessor :to_perform

    ##
    # Contains an array of commands to run for the currently parsed hook
    # This gets reset to [] every time a new hook is being parsed
    attr_accessor :commands_to_run

    ##
    # Initializes a new Hooks object
    # Provide the environment (e.g. :staging, :production) to parse
    def initialize(environment)
      @environment     = environment
      @to_perform      = []
      @commands_to_run = []
    end

    ##
    # Parses the configuration file and loads all the
    # configuration values into the GitPusshuTen::Configuration instance
    def parse!(hooks_file)
      instance_eval(File.read(hooks_file))
      self
    end

    ##
    # Perform On
    # Helper method used to configure the hooks.rb file
    def perform_on(*environments, &configuration)
      if environments.flatten.include?(environment)
        configuration.call
      end
    end

    ##
    # Pre
    # A method for setting pre-hooks inside the perform_on block
    # Resets the "commands_to_run" variable to an empty array so that
    # there's a clean array to work with the next set of commands.
    # The "commands.call" invokes all the "run(<command>)" the user
    # provided in the hooks.rb configuration file and extracts the strings
    # of commands to run. This array is then passed into a newly made Hook object
    # which is again stored into the "to_perform" array.
    def pre(name, &commands)
      @commands_to_run = []
      commands.call
      @to_perform << Hook.new({
        :type     => :pre,
        :name     => name,
        :commands => commands_to_run
      })
    end

    ##
    # Post
    # A method for setting post-hooks inside the perform_on block
    # Resets the "commands_to_run" variable to an empty array so that
    # there's a clean array to work with the next set of commands.
    # The "commands.call" invokes all the "run(<command>)" the user
    # provided in the hooks.rb configuration file and extracts the strings
    # of commands to run. This array is then passed into a newly made Hook object
    # which is again stored into the "to_perform" array.
    def post(name, &commands)
      @commands_to_run = []
      commands.call
      @to_perform << Hook.new({
        :type     => :post,
        :name     => name,
        :commands => commands_to_run
      })
    end

    ##
    # Run
    # A method for setting commands on a
    # post-hook or pre-hook inside the perform_on block
    def run(command)
      @commands_to_run << command
    end

    ##
    # Pre Hooks
    # Returns an array of pre-hooks
    def pre_hooks
      @to_perform.map do |hook|
        next unless hook.type.eql? :pre
        hook
      end.compact
    end

    ##
    # Post Hooks
    # Returns an array of post-hooks
    def post_hooks
      @to_perform.map do |hook|
        next unless hook.type.eql? :post
        hook
      end.compact
    end

  end
end