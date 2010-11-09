module GitPusshuTen
  module Helpers
    module Commands
      module Push

        def confirm_remote!
          unless git.has_remote?(environment.name)
            GitPusshuTen::Log.error "Cannot push to #{y(e.name)} because the remote does not exist."
            if configuration.found?
              add_remote! if add_remote?
            else
              GitPusshuTen::Log.error "Could not find any configuration for #{y(e.name)} in your #{y(".gitpusshuten/config.rb")} file."
              GitPusshuTen::Log.error "Please add it and run #{y("gitpusshuten setup remote for #{e.name}")} to set it up with git remote."
            end
            exit
          end
        end

        def add_remote?
          GitPusshuTen::Log.message "There appears to be a configuration for #{y(e.name)} in your #{y(".gitpusshuten/config.rb")} file."
          GitPusshuTen::Log.message "Would you like to run #{y("gitpusshuten setup remote for #{y(e.name)}")} now to set it up?"
          yes?
        end

        def add_remote!
          git.add_remote(e.name, c.user + '@' + c.ip + ':' + e.app_dir)
          GitPusshuTen::Log.message("The #{y(e.name)} remote has been added:")
          GitPusshuTen::Log.message(c.user + '@' + c.ip + ':' + e.app_dir + "\n\n")
        end

      end
    end
  end
end