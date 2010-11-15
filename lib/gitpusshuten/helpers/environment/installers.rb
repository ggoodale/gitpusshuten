module GitPusshuTen
  module Helpers
    module Environment
      module Installers

        ##
        # Installs the specified package(s)
        def install!(utility)
          ensure_aptitude_installed!
          execute_as_root("aptitude update; aptitude install -y #{utility}")
        end

        ##
        # Uninstalls the specified package(s)
        def uninstall!(utility)
          ensure_aptitude_installed!
          execute_as_root("aptitude remove -y #{utility}")
        end

        ##
        # Installs PushAnd
        def install_pushand!      
          download_packages!(home_dir)
          command = "cd #{home_dir}; cp -R gitpusshuten-packages/pushand/ .; chown -R #{c.user}:#{c.user} pushand;"
          command += "'#{home_dir}/pushand/pushand_server_uninstall'; '#{home_dir}/pushand/pushand_server_install'"
          execute_as_root(command)
          clean_up_packages!(home_dir)
        end

        ##
        # Installs a generated .gitconfig
        def install_gitconfig!
          command  = "cd #{home_dir}; echo -e \"[receive]\ndenyCurrentBranch = ignore\" > .gitconfig;"
          command += "chown #{c.user}:#{c.user} .gitconfig"
          execute_as_root(command)
        end

        ##
        # Determines whether the specified utility has been installed or not
        def installed?(utility)
          return false if execute_as_root("which #{utility}").nil?
          true
        end

        ##
        # Ensures that the aptitude package manager is installed
        def ensure_aptitude_installed!
          if not installed?('aptitude')
            Spinner.return :message => "Ensuring package manager is installed and up to date.." do
              execute_as_root!('apt-get update; apt-get install -y aptitude')
              g('Done!')
            end
          end
        end

      end
    end
  end
end