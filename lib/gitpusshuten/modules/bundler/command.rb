module GitPusshuTen
  module Commands
    class Bundler < GitPusshuTen::Commands::Base
      description "[Module] Bundler commands."
      usage       "bundler <command> <environment> environment"
      example     "gitpusshuten bundler bundle staging environment   # Bundles an application's gems for the specified environment."

      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
      end

      ##
      # Bundles gems
      def perform_bundle!
        GitPusshuTen::Log.message "Bundling Gems for #{y(c.application)} (#{y(e.name)} environment)."
        installed = e.installed?('bundle')
        if not installed
          GitPusshuTen::Log.message "Couldn't find Bundler, installing the gem."
          Spinner.return :message => "Installing Bundler.." do
            e.execute_as_user('gem install bundler --no-ri --no-rdoc')
            installed = e.installed?('bundle')
            if not installed
              r("Unable to install Bundler.")
            else
              g("Done!")
            end
          end
        end
        
        exit if not installed
        
        Spinner.return :message => "Bundling Gems for #{y(c.application)}", :put => true do
          e.execute_as_user("cd '#{e.app_dir}'; bundle install --without test development")
        end
      end

    end
  end
end