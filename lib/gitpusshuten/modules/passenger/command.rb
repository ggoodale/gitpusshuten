module GitPusshuTen
  module Commands
    class Passenger < GitPusshuTen::Commands::Base
      description "[Module] Phusion Passenger commands."
      usage       "passenger <command> for <environment>"
      example     "gitpusshuten passenger install for staging      # Installs Phusion Passenger with the NginX or Apache2 web server"
      example     "gitpusshuten passenger update for staging       # Updates Phusion Passenger and the NginX or Apache2 web server if a new version is available"
      example     "gitpusshuten passenger restart for production   # Restarts the Passenger instance for the specified environment"

      ##
      # Contains the webserver we're working with
      # Either NginX or Apache
      attr_accessor :webserver

      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
      end
      
      ##
      # Restarts a Passenger instance for the specified environment
      def perform_restart!
        message "Restarting Passenger for #{y(c.application)} (#{y(e.name)} environment)."
        e.execute_as_user("cd #{e.app_dir}; mkdir -p tmp; touch tmp/restart.txt")
      end
      
      ##
      # Installs Phusion Passenger
      def perform_install!
        
        if not e.installed?('gem')
          error "Could not find RubyGems."
          error "Install RVM (Ruby Version Manager) and at least one Ruby version."
          error "To do this, run: #{y("gitpusshuten rvm install for #{e.name}")}."
          exit
        end
        
        ##
        # If no web server is specified, it'll prompt the user to
        # select one of the available (NginX or Apache)
        if webserver.nil?
          message "For which web server would you like to install #{y('Phusion Passenger')}?"
          @webserver = webserver?
        end
        
        message "Starting #{y('Phusion Passenger')} installation for #{y(webserver)}!"
                
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
            e.install!("libcurl4-openssl-dev")
          end
          
          ##
          # Install dependencies for installing Apache
          if apache?
            e.install!("libcurl4-openssl-dev apache2-mpm-prefork apache2-prefork-dev libapr1-dev libaprutil1-dev")
          end
          
          g("Done!")
        end
        
        if not @updating
          standard "Installing #{y('Phusion Passenger')} and #{y(webserver)}."
        else
          standard "Updating #{y('Phusion Passenger')} and #{y(webserver)}."
        end
        
        Spinner.return :message => "This may take a while.." do
          
          ##
          # Run the Passenger NginX installation module if we're working with NginX
          if nginx?
            e.execute_as_root("passenger-install-nginx-module --auto --auto-download --prefix=/etc/nginx")
          end
          
          ##
          # Run the Passenger Apache installation module if we're working with Apache
          if apache?
            e.execute_as_root("passenger-install-apache2-module --auto")
          end
          
          g("Done!")
        end
        
        ##
        # Configures NginX to setup a managable vhost environment like Apache2
        if nginx?
          GitPusshuTen::Initializer.new("nginx", "setup", "#{e.name}", "environment")
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
          message "#{y('Phusion Passenger')} and #{y(webserver)} have been installed!"
        else
          message "#{y('Phusion Passenger')} and #{y(webserver)} have been updated!"
        end
        
        if nginx?
          message "NginX directory: #{y('/etc/nginx')}"
        end
        
        if apache?
          message "Apache directory: #{y('/etc/apache2')}"
          GitPusshuTen::Initializer.new('apache', 'create-vhost', 'for', "#{e.name}")
        end
      end

      ##
      # Updates the Passenger Gem and NginX or Apache2 itself
      # Compares the currently installed Passenger Gem with the latest (stable) version
      # on RubyGems.org to see if anything newer than the current version is out.
      # If there is, then it will continue to update NginX/Apache2 using Phussions's NginX/Apache2 installation module.
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
          error "Install RVM (Ruby Version Manager) and at least one Ruby version."
          error "To do this, run: #{y("gitpusshuten rvm install for #{e.name}")}."
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
            g("Found!")
          end
        end
        
        if not @passenger_installed
          error "Passenger has not been installed for #{y(@ruby_version)}"
          error "If you want to install Passenger, please run the following command:"
          error y("gitpusshuten passenger install for #{e.name}")
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
        
        message "Phusion Passenger #{y(@latest_passenger_version)} is out!"
        message "You are currently using version #{y(@current_passenger_version)}.\n\n"
        message "Would you like to update Phusion Passenger?"
        message "This will update the #{y('Phusion Passenger Gem')} as well as #{y(webserver)} and #{y("Phusion Passenger's #{webserver} Module")}."
        
        ##
        # Prompt user for confirmation for the update
        if yes?
          
          ##
          # Search for NginX installation directory by finding the configuration file
          if nginx?
            find_nginx_conf!
            
            if not @nginx_conf
              error "Could not find the NginX configuration file in #{y('/etc/nginx')} or #{y('/etc/nginx/conf')}."
              exit 
            end
          end
          
          ##
          # Ensures the Apache2 configuration file exists
          if apache?
            find_apache2_conf!
            
            if not @apache2_conf
              error "Could not find the Apache2 configuration file in #{y('/etc/apache2')}."
              exit
            end
          end
          
          ##
          # Installation directory has been found
          message "#{y(webserver)} installation found in #{y(@nginx_conf || @apache2_conf)}."
          
          ##
          # Invoke the installation command to install NginX
          @updating = true
          perform_install!
          
          ##
          # Update the webserver configuration file
          message "The #{y(webserver)} configuration file needs to be updated with the new #{y('Passenger')} version."
          message "Invoking #{y("gitpusshuten #{webserver.downcase} update-configuration for #{e.name}")} for you..\n\n\n"
          GitPusshuTen::Initializer.new([webserver.downcase, 'update-configuration', 'for', "#{e.name}"])
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

      ##
      # Finds and sets the NginX Conf path
      def find_nginx_conf!
        ##
        # NginX Conf path you get from Passenger
        if e.file?('/etc/nginx/conf/nginx.conf')
          @nginx_conf = '/etc/nginx/conf/nginx.conf'
        end
        
        ##
        # NginX Conf path you get from Aptitude
        if e.file?('/etc/nginx/nginx.conf')
          @nginx_conf = '/etc/nginx/nginx.conf'
        end
      end

      ##
      # Finds and sets the Apache2 Conf path
      def find_apache2_conf!
        ##
        # Apache2 Conf path you get from Aptitude
        if e.file?('/etc/apache2/apache2.conf')
          @apache2_conf = '/etc/apache2/apache2.conf'
        end
      end

    end
  end
end