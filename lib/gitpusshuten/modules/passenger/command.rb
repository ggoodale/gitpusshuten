module GitPusshuTen
  module Commands
    class Passenger < GitPusshuTen::Commands::Base
      description "[Module] Phusion Passenger commands."
      usage       "passenger <command> for <environment>"
      example     "passenger install for staging      # Installs Phusion Passenger with the NginX web server"
      example     "passenger update for staging       # Updates Phusion Passenger and the NginX web server if a new version is available"
      example     "passenger restart for production   # Restarts the Passenger instance for the specified environment"

      ##
      # Passenger specific attributes/arguments
      attr_accessor :command

      ##
      # Contains the webserver we're working with
      # Either NginX or Apache
      attr_accessor :webserver

      ##
      # Initializes the Passenger command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
      end

      ##
      # Performs the Passenger command
      def perform!
        if respond_to?("perform_#{command}!")
          send("perform_#{command}!")
        else
          GitPusshuTen::Log.error "Unknown RVM command: <#{y(command)}>"
          GitPusshuTen::Log.error "Run #{y('gitpusshuten help passenger')} for a list rvm commands."
        end
      end
      
      ##
      # Restarts a Passenger instance for the specified environment
      def perform_restart!
        GitPusshuTen::Log.message "Restarting Passenger for #{y(c.application)} (#{y(e.name)} environment)."
        e.execute_as_user("cd #{e.app_dir}; mkdir -p tmp; touch tmp/restart.txt")
      end
      
      ##
      # Installs Phusion Passenger
      def perform_install!
        
        if not e.installed?('gem')
          GitPusshuTen::Log.error "Could not find RubyGems."
          GitPusshuTen::Log.error "Install RVM (Ruby Version Manager) and at least one Ruby version."
          GitPusshuTen::Log.error "To do this, run: #{y("gitpusshuten rvm install for #{e.name}")}."
          exit
        end
        
        ##
        # If no web server is specified, it'll prompt the user to
        # select one of the available (NginX or Apache)
        if webserver.nil?
          GitPusshuTen::Log.message "For which web server would you like to install #{y('Phusion Passenger')}?"
          @webserver = webserver?
        end
        
        GitPusshuTen::Log.message "Starting #{y('Phusion Passenger')} installation for #{y(webserver)}!"
        
        ##
        # Install Passenger (NginX Module) and NginX itself
        if nginx? and not @updating
          while @prefix_path.nil? or not @prefix_path =~ /^\//
            GitPusshuTen::Log.message "Where would you like to install NginX? Provide an #{y('absolute')} path."
            @prefix_path = ask("Leave empty if you want to use the default: /opt/nginx")
            @prefix_path = '/opt/nginx' if @prefix_path.empty?
          end
        end
        
        ##
        # Install the latest Passenger Gem
        Spinner.return :message => "Installing latest Phusion Passenger Gem.." do
          e.execute_as_root("gem install passenger --no-ri --no-rdoc")
          g("Done!")
        end
        
        ##
        # Install dependencies for Passenger
        Spinner.return :message => "Ensuring #{y('Phusion Passenger')} dependencies are installed.." do
          
          ##
          # Install dependencies for installing NginX
          if nginx?
            e.execute_as_root("aptitude update; aptitude install -y libcurl4-openssl-dev libcurl4-gnutls-dev")
          end
          
          ##
          # Install dependencies for installing Apache
          if apache?
            e.execute_as_root("aptitude update; aptitude install -y libcurl4-openssl-dev libcurl4-gnutls-dev apache2-mpm-prefork apache2-prefork-dev libapr1-dev libaprutil1-dev")
          end
          
          g("Done!")
        end
        
        if not @updating
          GitPusshuTen::Log.standard "Installing #{y('Phusion Passenger')} and #{y(webserver)}."
        else
          GitPusshuTen::Log.standard "Updating #{y('Phusion Passenger')} and #{y(webserver)}."
        end
        
        Spinner.return :message => "This may take a while.." do
          ##
          # Run the Passenger NginX installation module if we're working with NginX
          if nginx?
            e.execute_as_root("passenger-install-nginx-module --auto --auto-download --prefix='#{@prefix_path}'")
          end
          
          ##
          # Run the Passenger Apache installation module if we're working with Apache
          if apache?
            e.execute_as_root("passenger-install-apache2-module --auto")
          end
          
          g("Done!")
        end
        
        ##
        # Inject the Passenger paths into the Apache2 configuration file
        if apache?
          Spinner.return :message => "Configuring Apache for Phusion Passenger.." do
            if not e.execute_as_root('cat /etc/apache2/apache2.conf').include?("passenger_module")
              if e.execute_as_root('passenger-config --root') =~ /\/usr\/local\/rvm\/gems\/(.+)\/gems\/passenger-.+/
                @ruby_version      = $1.chomp.strip
                @passenger_version = e.execute_as_root('passenger-config --version').chomp.strip
              end
              
              e.execute_as_root <<-PASSENGER
cat <<-CONFIG >> /etc/apache2/apache2.conf

LoadModule passenger_module /usr/local/rvm/gems/#{@ruby_version}/gems/passenger-#{@passenger_version}/ext/apache2/mod_passenger.so
PassengerRoot /usr/local/rvm/gems/#{@ruby_version}/gems/passenger-#{@passenger_version}
PassengerRuby /usr/local/rvm/wrappers/#{@ruby_version}/ruby

CONFIG
              PASSENGER
            end
            g('Done!')
          end # spinner
        end
        
        if not @updating
          GitPusshuTen::Log.message "#{y('Phusion Passenger')} and #{y(webserver)} have been installed!"
        else
          GitPusshuTen::Log.message "#{y('Phusion Passenger')} and #{y(webserver)} have been updated!"
        end
      end

      ##
      # Updates the Passenger Gem and NginX itself
      # Compares the currently installed Passenger Gem with the latest (stable) version
      # on RubyGems.org to see if anything newer than the current version is out.
      # If there is, then it will continue to update NginX using Phussions's NginX installation module.
      def perform_update!
        prompt_for_root_password!
        
        ##
        # If no web server is specified, it'll prompt the user to
        # select one of the available (NginX or Apache)
        if webserver.nil?
          @webserver = webserver?
        end
        
        ##
        # Check if RubyGems (RVM + Ruby) has been installed
        Spinner.return :message => "Checking if RubyGems is installed.." do
          @rubygems_installed = e.installed?('gem')
          if not @rubygems_installed
            r("Couldn't find RubyGems.")
          else
            g("Done!")
          end
        end
        
        if not @rubygems_installed
          GitPusshuTen::Log.error "Install RVM (Ruby Version Manager) and at least one Ruby version."
          GitPusshuTen::Log.error "To do this, run: #{y("gitpusshuten rvm install for #{e.name}")}."
          exit
        end
        
        ##
        # Check if Phusion Passenger is installed
        Spinner.return :message => "Checking if Phusion Passenger is installed.." do
          @passenger_installed = e.installed?("passenger")
          if not @passenger_installed
            @ruby_version = e.execute_as_root("ruby -v").chomp
            r("Couldn't find Phusion Passenger")
          else
            g("Done!")
          end
        end
        
        if not @passenger_installed
          GitPusshuTen::Log.error "Passenger has not been installed for #{y(@ruby_version)}"
          GitPusshuTen::Log.error "If you want to install Passenger, please run the following command:"
          GitPusshuTen::Log.error y("gitpusshuten passenger install for #{e.name}")
          exit
        end
        
        ##
        # Check if a newer version of Phusion Passenger Gem is available
        Spinner.return :message => "Checking if there's a newer (stable) Phusion Passenger available.." do
          @latest_passenger_version  = GitPusshuTen::Gem.new(:passenger).latest_version
          @current_passenger_version = e.execute_as_root("passenger-config --version").chomp.strip
          if @latest_passenger_version > @current_passenger_version
            @new_passenger_version_available = true
            y("There appears to be a newer version of Phusion Passenger available!")
          else
            g("Your Phusion Passenger is #{@current_passenger_version}. This is the latest version.")
          end
        end
        
        exit unless @new_passenger_version_available
        
        GitPusshuTen::Log.message "Phusion Passenger #{y(@latest_passenger_version)} is out!"
        GitPusshuTen::Log.message "You are currently using version #{y(@current_passenger_version)}.\n\n"
        GitPusshuTen::Log.message "Would you like to update Phusion Passenger?"
        GitPusshuTen::Log.message "This will update the #{y('Phusion Passenger Gem')} as well as #{y(webserver)} and #{y("Phusion Passenger's #{webserver} Module")}."
        
        ##
        # Prompt user for confirmation for the update
        if yes?
          
          ##
          # Loads webserver configuration file if it exists to figure out the
          # webserver installation directory. Default to nil if no configuration could
          # be found. If this is the case, the user will be prompted to provide the
          # webserver installation directory.
          #
          # This only applies to NginX since Apache2 apparently always installs in /etc/apache2
          load_configuration!(webserver)
          @updating      = true
          @prefix_path   = @installation_dir || '/opt/nginx'
          @path_found  ||= false
          
          ##
          # Search for NginX installation directory by finding the configuration file
          if nginx?
            while not @path_found
              if not e.file?(File.join(@prefix_path, 'conf', 'nginx.conf'))
                GitPusshuTen::Log.warning "Could not find the #{y('NginX')} installation directory."
                @prefix_path = ask("Please provide the absolute path to the direction in which you've previously installed #{y('NginX')}.")
              else
                @path_found = true
              end
            end
          end
          
          ##
          # Ensures the Apache2 configuration file exists
          if apache?
            if not e.file?(File.join(@prefix_path, 'apache2.conf'))
              GitPusshuTen::Log.error "Could not find Apache configuration file in #{y(File.join(@prefix_path, 'apache2.conf'))}."
              exit
            end
          end
          
          ##
          # Installation directory has been found
          GitPusshuTen::Log.message "#{y(webserver)} installation found in #{y(@prefix_path)}."
          
          ##
          # Write local webserver configuration file
          if nginx?
            File.open(File.join(local.gitpusshuten_dir, 'nginx', 'config.yml'), 'w') do |file|
              file << YAML::dump({
                :installation_dir         => @prefix_path,
                :configuration_directory  => File.join(@prefix_path, 'conf'),
                :configuration_file       => File.join(@prefix_path, 'conf', 'nginx.conf')
              })
            end
          end
          
          ##
          # Invoke the installation command to install NginX
          perform_install!
          
          ##
          # Update the webserver configuration file
          GitPusshuTen::Log.message "The #{y(webserver)} configuration file needs to be updated with the new #{y('Passenger')} version."
          GitPusshuTen::Log.message "Invoking #{y("gitpusshuten #{webserver.downcase} update-configuration for #{e.name}")} for you..\n\n\n"
          GitPusshuTen::Initializer.new([webserver.downcase, 'update-configuration', 'for', "#{e.name}"])
        end
      end

      ##
      # Load in configuration if present
      def load_configuration!(webserver)
        if nginx?
          config_file_path = File.join(local.gitpusshuten_dir, webserver.downcase, 'config.yml')
          if File.exist?(config_file_path)
            GitPusshuTen::Log.message "Loading configuration from #{y(File.join(local.gitpusshuten_dir, webserver, 'config.yml'))}."
            config = YAML::load(File.read(config_file_path))
            @installation_dir = config[:installation_dir]
          end
        end
        if apache?
          @installation_dir = '/etc/apache2'
          @path_found       = true
        end
      end

      ##
      # Returns true if we're working with NginX
      def nginx?
        webserver == 'NginX'
      end

      ##
      # Returns true if we're working with Apache
      def apache?
        webserver == 'Apache'
      end

      ##
      # Prompts the user to select a webserver
      def webserver?
        choose do |menu|
          menu.prompt = ''
          menu.choice('NginX')
          menu.choice('Apache')
        end
      end

    end
  end
end