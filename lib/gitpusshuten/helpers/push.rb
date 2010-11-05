module GitPusshuTen
  module Helpers
    module Push

      def confirm_remote!
        unless git.has_remote?(environment.name)
          GitPusshuTen::Log.error "Cannot push to #{environment.name.to_s.color(:yellow)} because the remote does not exist."
          if configuration.found?
            add_remote! if add_remote?
          else
            GitPusshuTen::Log.error "Could not find any configuration for #{environment.name.to_s.color(:yellow)} in your #{".gitpusshuten/config.rb".color(:yellow)} file."
            GitPusshuTen::Log.error "Please add it and run #{"gitpusshuten setup remote for #{environment.name}".color(:yellow)} to set it up with git remote."
          end
          exit
        end
      end

      def add_remote?
        GitPusshuTen::Log.message "There appears to be a configuration for #{environment.name.to_s.color(:yellow)} in your #{".gitpusshuten/config.rb".color(:yellow)} file."
        GitPusshuTen::Log.message "Would you like to run #{"gitpusshuten setup remote for #{environment.name}".color(:yellow)} now to set it up?"
        choose do |menu|
          menu.prompt = ''
          menu.choice('Yes') { true  }
          menu.choice('No')  { false }
        end
      end

      def add_remote!
        git.add_remote(
          environment.name,
          configuration.user + '@' + configuration.ip + ':' + environment.application_root
        )
        GitPusshuTen::Log.message("The " + environment.name.to_s.color(:yellow) + " remote has been added:")
        GitPusshuTen::Log.message(configuration.user + '@' + configuration.ip + ':' + environment.application_root + "\n\n")
      end
      
    end
  end
end