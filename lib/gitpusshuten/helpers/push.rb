module GitPusshuTen
  module Helpers
    module Push
      
      def confirm_remote!
        unless git.has_remote?(environment.name)
          GitPusshuTen::Log.error "Cannot push to #{environment.name.to_s.color(:yellow)} because the remote does not exist."
          GitPusshuTen::Log.error "If you've specified this remote in your #{".gitpusshuten/config.rb".color(:yellow)}, don't forget to add it to your git repository."
          GitPusshuTen::Log.error "To do that, you must run: " + "gitpusshuten setup remote for #{environment.name}\n".color(:yellow)
          add_remote! if add_remote?
          exit
        end
      end

      def add_remote?
        GitPusshuTen::Log.message "Would you like to run #{"gitpusshuten setup remote for #{environment.name}".color(:yellow)} now?"
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