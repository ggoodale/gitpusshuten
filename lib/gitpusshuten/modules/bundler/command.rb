module GitPusshuTen
  module Commands
    class Bundler < GitPusshuTen::Commands::Base
      description "[Module] Bundler commands."
      usage       "bundler <command> for <environment>"
      example     "bundler bundle for staging         # Installs Passenger with the NginX web server"

      ##
      # Passenger specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the Bundler command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
      end

      ##
      # Performs the Bundler command
      def perform!
        if respond_to?("perform_#{command}!")
          send("perform_#{command}!")
        else
          GitPusshuTen::Log.error "Unknown RVM command: <#{y(command)}>"
          GitPusshuTen::Log.error "Run #{y('gitpusshuten help bundler')} for a list bundler commands."
        end
      end
      
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
              g("DONE")
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