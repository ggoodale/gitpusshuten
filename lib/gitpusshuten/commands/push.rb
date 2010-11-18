module GitPusshuTen
  module Commands
    class Push < GitPusshuTen::Commands::Base
      description "Pushes a branch, tag or ref to the specified environment."
      usage       "push <command> <type> to <environment>"
      example     "heavenly push branch develop to staging                                    # Pushes the specified branch to the staging environment."
      example     "heavenly push tag 1.0.3 to staging                                         # Pushes the specified tag to the staging environment."
      example     "heavenly push ref 2dbec02aa0b8604b8512e2fcbb8aac582c7f6a73 to production   # Pushes the specified ref to the production environment."

      attr_accessor :type

      def initialize(*objects)
        super
        perform_hooks!
        
        @command = cli.arguments.shift
        @type    = cli.arguments.shift
        
        help if type.nil? or e.name.nil?
        
        set_remote!
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
        git.add_remote(e.name, "ssh://#{c.user}@#{c.ip}:#{c.port}/#{e.app_dir}")
      end

    end
  end
end