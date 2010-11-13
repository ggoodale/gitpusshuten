module GitPusshuTen
  module Commands
    class Push < GitPusshuTen::Commands::Base
      description "Pushes a branch, tag or ref to the specified environment."
      usage       "push <branch|tag|ref> to <environment>"
      example     "gitpusshuten push branch develop to staging"
      example     "gitpusshuten push tag develop to staging"
      example     "gitpusshuten push ref master to production"

      attr_accessor :command, :type

      def initialize(*objects)
        super
        perform_hooks!
        
        @command = cli.arguments.shift
        @type    = cli.arguments.shift
        
        help if type.nil? or e.name.nil?
        
        set_remote!
      end

      def perform!        
        if respond_to?("perform_#{command}!")
          send("perform_#{command}!")
        else
          error "Unknown setup command: <#{y(command)}>"
          error "Run #{y("gitpusshuten help push")} for a list push commands."
        end
      end

      ##
      # Pushes the specified branch to the remote environment.
      def perform_branch!
        message "Pushing branch #{y(type)} to the #{y(e.name)} environment."
        git.push(:branch, type).to(e.name)
      end

      ##
      # Pushes the specified tag to the remote environment.
      def perform_tag!
        message "Pushing tag #{y(type)} to the #{y(e.name)} environment."
        git.push(:tag, type).to(e.name)
      end

      ##
      # Pushes the specified ref to the remote environment.
      def perform_ref!
        message "Pushing ref #{y(type)} to the #{y(e.name)} environment."
        git.push(:ref, type).to(e.name)
      end

      ##
      # Adds the remote
      def set_remote!
        git.remove_remote(e.name) if git.has_remote?(e.name)
        git.add_remote(e.name, c.user + '@' + c.ip + ':' + e.app_dir)
      end

    end
  end
end