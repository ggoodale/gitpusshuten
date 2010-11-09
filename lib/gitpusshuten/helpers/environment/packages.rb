module GitPusshuTen
  module Helpers
    module Environment
      module Packages

        ##
        # Downloads the gitpusshuten packages
        def download_packages!(path, user = 'user')
          send("execute_as_#{user}", "cd #{path}; git clone git://github.com/meskyanichi/gitpusshuten-packages.git")
        end

        ##
        # Cleans up the gitpusshuten-packages git repository
        def clean_up_packages!(path, user = 'user')
          send("execute_as_#{user}", "rm -rf '#{File.join(path, 'gitpusshuten-packages')}'")
        end

      end
    end
  end
end
