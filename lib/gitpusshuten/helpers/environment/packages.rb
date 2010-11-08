module GitPusshuTen
  module Helpers
    module Environment
      module Packages

        ##
        # Downloads the gitpusshuten packages
        def download_gitpusshuten_packages!
          execute_as_user("cd #{home_dir}; git clone git://github.com/meskyanichi/gitpusshuten-packages.git")
        end

        ##
        # Cleans up the gitpusshuten-packages git repository
        def clean_up_gitpusshuten_packages!
          execute_as_user("rm -rf '#{packages_dir}'")
        end

        ##
        # Returns the path to the (downloaded) gitpusshuten packages
        def packages_dir
          File.join(home_dir, 'gitpusshuten-packages')
        end

      end
    end
  end
end
