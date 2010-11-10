module GitPusshuTen
  module Commands
    class Nginx < GitPusshuTen::Commands::Base
      description "[Module] NginX commands."
      usage       "nginx <command> for <environment>"
      example     "nginx setup for staging                  # Sets up a managable vhost environment."
      example     "nginx update-configuration for staging   # Only for Passenger users, when updating Ruby/Passenger versions."
      example     "nginx update-vhost for staging           # Pushes your local vhost to the server for the specified environment, and restarts NginX."
      example     "nginx delete-vhost for production        # Deletes the remote vhost for the specified environment."
      example     "nginx start for staging                  # Starts NginX."
      example     "nginx stop for production                # Stops NginX."
      example     "nginx restart for production             # Restarts NginX."
      example     "nginx reload for production              # Reloads NginX."

      ##
      # Passenger specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the Nginx command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
        
        @command = @command.underscore
        
        ##
        # Default Configuration
        @installation_dir         = "/opt/nginx"
        @installation_dir_found   = false
        @configuration_file_found = false
      end

      ##
      # Performs the Passenger command
      def perform!
        if respond_to?("perform_#{command}!")
          send("perform_#{command}!")
        else
          GitPusshuTen::Log.error "Unknown Nginx command: <#{y(command)}>"
          GitPusshuTen::Log.error "Run #{y('gitpusshuten help nginx')} for a list setup commands."
        end
      end

      ##
      # Starts Nginx
      def perform_start!
        ensure_nginx_executable_is_installed!
        GitPusshuTen::Log.message "Starting Nginx."
        puts e.execute_as_root("/etc/init.d/nginx start")
      end

      ##
      # Stops Nginx
      def perform_stop!
        ensure_nginx_executable_is_installed!
        GitPusshuTen::Log.message "Stopping Nginx."
        puts e.execute_as_root("/etc/init.d/nginx stop")
      end

      ##
      # Restarts Nginx
      def perform_restart!
        ensure_nginx_executable_is_installed!
        GitPusshuTen::Log.message "Restarting Nginx."
        perform_stop!
        perform_start!
      end

      ##
      # Reload Nginx
      def perform_reload!
        ensure_nginx_executable_is_installed!
        GitPusshuTen::Log.message "Reloading Nginx."
        puts e.execute_as_root("/etc/init.d/nginx reload")
      end

      ##
      # Sets up a vHost directory and injects a snippet into the nginx.conf
      def perform_setup!
        load_configuration!
        find_correct_paths!
        
        ##
        # Set configuration directory
        @configuration_directory = @configuration_file.split('/')
        @configuration_directory.pop
        @configuration_directory = @configuration_directory.join('/')
        
        ##
        # Creates a tmp dir
        local.create_tmp_dir!
        
        ##
        # Downloads the NGINX configuration file to tmp dir
        GitPusshuTen::Log.message "Downloading NGINX configuration file to #{local.tmp_dir}."
        e.scp_as_root(:download, @configuration_file, local.tmp_dir)
        @configuration_file_name = @configuration_file.split('/').last
        
        ##
        # Set the path to the downloaded file
        local_file = File.join(local.tmp_dir, @configuration_file_name)
        
        if not File.read(local_file).include?('include vhosts/*;')
          GitPusshuTen::Log.message "Configuring NGINX configuration file."
          
          ##
          # Inject the 'include vhosts/*'
          contents = File.read(local_file).sub(/http(\s|\t|\n){0,}\{/, "http {\n\s\s\s\sinclude vhosts/*;\n")
          File.open(local_file, 'w') do |file|
            file << contents
          end
          
          ##
          # Make a backup of the old nginx.conf
          GitPusshuTen::Log.message "Creating a backup of old NGINX configuration file."
          e.execute_as_root("cp '#{@configuration_file}' '#{@configuration_file}.backup'")
          
          ##
          # Upload the file back
          GitPusshuTen::Log.message "Updating NGINX configuration file."
          e.scp_as_root(:upload, local_file, @configuration_file)
          
          ##
          # Create the vhosts dir on the server
          @vhosts_directory = File.join(@configuration_directory, 'vhosts')
          GitPusshuTen::Log.message "Creating #{@vhosts_directory} directory."
          e.execute_as_root("mkdir #{@vhosts_directory}")
        end
        
        ##
        # Removes the tmp dir
        GitPusshuTen::Log.message "Cleaning up #{local.tmp_dir}"
        local.remove_tmp_dir!
        
        ##
        # Create NGINX directory
        # Create NGINX vhost file (if it doesn't already exist)
        # Create or Overwrite NGINX config file that stores the vhosts directory
        local.execute("mkdir -p '#{File.join(local.gitpusshuten_dir, 'nginx')}'")
        vhost_file  = File.join(local.gitpusshuten_dir, 'nginx', "#{e.name}.vhost")
        config_file = File.join(local.gitpusshuten_dir, 'nginx', "config.yml")

        if not File.exist?(vhost_file)
          File.open(vhost_file, 'w') do |file|
            file << "server {\n"
            file << "\s\slisten 80;\n"
            file << "\s\sserver_name mydomain.com www.mydomain.com;\n"
            file << "\s\sroot #{e.app_dir}/public;\n"
            file << "\s\s# passenger_enabled on; # for rack (rails/sinatra/merb/etc users)\n"
            file << "}\n"
          end
        end
        
        File.open(config_file, 'w') do |file|
          file << YAML::dump({
            :installation_dir         => @installation_dir,
            :configuration_directory  => @configuration_directory,
            :configuration_file       => @configuration_file
          })
        end
      end

      ##
      # Updates a local vhost
      def perform_update_vhost!
        load_configuration!
        find_correct_paths!
        
        vhost_file = File.join(local.gitpusshuten_dir, 'nginx', "#{e.name}.vhost")
        if File.exist?(vhost_file)
          GitPusshuTen::Log.message "Uploading #{y(vhost_file)} to " +
          y(File.join(@configuration_directory, 'vhosts', "#{e.sanitized_app_name}.#{e.name}.vhost!"))

          e.scp_as_root(:upload, vhost_file, File.join(@configuration_directory, 'vhosts', "#{e.sanitized_app_name}.#{e.name}.vhost"))
          perform_restart!
        else
          GitPusshuTen::Log.error "Could not locate vhost file #{y(vhost_file)}."
          GitPusshuTen::Log.error "Did you run #{y("gitpusshuten nginx setup for #{e.name}")} yet?"
          exit
        end
      end

      ##
      # Deletes a vhost
      def perform_delete_vhost!
        load_configuration!
        find_correct_paths!
        
        vhost_file = File.join(@configuration_directory, 'vhosts', "#{e.sanitized_app_name}.#{e.name}.vhost")
        if environment.file?(vhost_file)
          GitPusshuTen::Log.message "Deleting #{y(vhost_file)}!"
          environment.execute_as_root("rm #{vhost_file}")
          perform_restart!
        else
          GitPusshuTen::Log.message "#{y(vhost_file)} does not exist."
          exit
        end
      end

      ##
      # Performs the Update Configuration command
      # This is particularly used when you change Passenger or Ruby versions
      # so these are updated in the nginx.conf file.
      def perform_update_configuration!
        load_configuration!
        find_correct_paths!
        
        if not e.file?("'#{@configuration_file}'")
          GitPusshuTen::Log.error "Could not find configuration file in #{y(@configuration_file)}."
          exit
        end
        
        GitPusshuTen::Log.message "Checking the #{y(@configuration_file)} for current Passenger configuration."
        config_contents = e.execute_as_root("cat '#{@configuration_file}'")
        if not config_contents.include? 'passenger_root' or not config_contents.include?('passenger_ruby')
          GitPusshuTen::Log.error "Could not find Passenger configuration, has it ever been set up?"
          exit
        end
        
        GitPusshuTen::Log.message "Checking if Passenger is installed under the #{y('default')} Ruby."
        if not e.installed?('passenger')
          GitPusshuTen::Log.message "Passenger isn't installed for the current Ruby, installing latest version now."
          Spinner.installing do
            e.execute_as_root('gem install passenger --no-ri --no-rdoc')
          end
        end
        
        GitPusshuTen::Log.message "Finding current Passenger version."
        if e.execute_as_root('passenger --version') =~ /Phusion Passenger version (\d+\.\d+\.\d+)/
          passenger_version = $1.chomp.strip
        else
          GitPusshuTen::Log.error "Could not find the current Passenger version."
          exit
        end
        
        GitPusshuTen::Log.message "Finding current version for the default Ruby."
        if e.execute_as_root('which ruby') =~ /\/usr\/local\/rvm\/rubies\/(.+)\/bin\/ruby/
          ruby_version = $1.chomp.strip
        else
          GitPusshuTen::Log.error "Could not find the current Ruby version."
          exit
        end
        
        puts <<-INFO
          
          [Detected Versions]
          
            Ruby Version:       #{ruby_version}
            Passenger Version:  #{passenger_version}
          
        INFO
        
        GitPusshuTen::Log.message "NginX will now be configured to work with the above versions."
        
        ##
        # Checks to see if Passengers WatchDog is available in the current Passenger gem
        # If it is not, then Passenger needs to run the "passenger-install-nginx-module" so it gets installed
        if not e.directory?("/usr/local/rvm/gems/#{ruby_version}/gems/passenger-#{passenger_version}/agents")
          GitPusshuTen::Log.message "\n\nPhusion Passenger has not yet been installed for this Ruby's Passenger Gem."
          GitPusshuTen::Log.message "You need to reinstall/update #{y('NginX')} and #{y('Passenger')} to proceed with the configuration."
          GitPusshuTen::Log.message "\nWould you like to reinstall/update #{y('NginX')} and #{y('Phusion Passenger')} to #{y(passenger_version)} for Ruby #{y(ruby_version)}?"
          GitPusshuTen::Log.message "NOTE: Your current NginX configuration will #{y('not')} be lost. This is a reinstall/update that #{y('does not')} remove your NginX configuration."
          
          if yes?
            GitPusshuTen::Log.message "Ensuring #{y('Phusion Passenger')} dependencies are installed."
            Spinner.installing do
              e.execute_as_root("aptitude update; aptitude install -y build-essential libcurl4-openssl-dev bison openssl libreadline5 libreadline5-dev curl git zlib1g zlib1g-dev libssl-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev")
            end
            
            GitPusshuTen::Log.message "Reinstalling/Updating #{y('Phusion Passenger')}."
            Spinner.installing_a_while do
              e.execute_as_root("passenger-install-nginx-module --auto --auto-download --prefix=#{@installation_dir}")
            end
          end
        end
        
        ##
        # Creates a tmp dir
        local.create_tmp_dir!
        
        ##
        # Downloads the NGINX configuration file to tmp dir
        GitPusshuTen::Log.message "Updating NginX configuration file."
        Spinner.configuring do
          e.scp_as_root(:download, @configuration_file, local.tmp_dir)
          @configuration_file_name = @configuration_file.split('/').last
          
          local_configuration_file = File.join(local.tmp_dir, @configuration_file_name)
          update = File.read(local_configuration_file)
          update.sub! /passenger_root \/usr\/local\/rvm\/gems\/(.+)\/gems\/passenger\-(.+)\;/,
                      "passenger_root /usr/local/rvm/gems/#{ruby_version}/gems/passenger-#{passenger_version};"
          
          update.sub! /passenger_ruby \/usr\/local\/rvm\/wrappers\/(.+)\/ruby\;/,
                      "passenger_ruby /usr/local/rvm/wrappers/#{ruby_version}/ruby;"
          
          File.open(local_configuration_file, 'w') do |file|
            file << update
          end
          
          ##
          # Create a backup of the current configuration file
          e.execute_as_root("cp '#{@configuration_file}' '#{@configuration_file}.backup.#{Time.now.to_i}'")
          
          ##
          # Upload the updated NginX configuration file
          e.scp_as_root(:upload, local_configuration_file, @configuration_file)
          
          ##
          # Remove the local tmp directory
          local.remove_tmp_dir!
        end
        
        GitPusshuTen::Log.message "NginX configuration file has been updated!"
        GitPusshuTen::Log.message y(@configuration_file)
        
        ##
        # Restart the NginX web server so the changes take effect
        perform_restart!
      end

      ##
      # Installs the Nginx executable if it does not exist
      def ensure_nginx_executable_is_installed!
        if not environment.file?("/etc/init.d/nginx")
          GitPusshuTen::Log.message "Installing NginX executable for starting/stopping/restarting/reloading Nginx."
          environment.download_packages!(e.home_dir, :root)
          environment.execute_as_root("cp '#{File.join(e.home_dir, 'gitpusshuten-packages', 'modules', 'nginx', 'nginx')}' /etc/init.d/nginx")
          environment.clean_up_packages!(e.home_dir, :root)
        end
      end

      ##
      # Attempts to find correct paths and prompts the user for them otherwise
      def find_correct_paths!
        GitPusshuTen::Log.message "Confirming NGINX installation directory location."
        while not @installation_dir_found
          if not e.directory?(@installation_dir)
            GitPusshuTen::Log.warning "Could not find NGINX in #{y(@installation_dir)}."
            GitPusshuTen::Log.message "Please provide the path to the installation directory."
            @installation_dir = ask('')
          else
            GitPusshuTen::Log.message "NGINX installation directory found in #{y(@installation_dir)}!"
            @installation_dir_found = true
          end
        end
        
        GitPusshuTen::Log.message "Confirming NGINX configuration file location."
        @configuration_file = File.join(@installation_dir, "conf", "nginx.conf") if @configuration_file.nil?
        while not @configuration_file_found
          if not environment.file?(@configuration_file)
            GitPusshuTen::Log.warning "Could not find the NGINX configuration file in #{y(@configuration_file)}."
            GitPusshuTen::Log.message "Please provide the (full/absolute) path to the NGINX configuration file. (e.g. #{y(File.join(@installation_dir, "conf", "nginx.conf"))})"
            @configuration_file = ask('')
          else
            GitPusshuTen::Log.message "NGINX configuration file found in #{y(@configuration_file)}!"
            @configuration_file_found = true
          end
        end
      end

      ##
      # Load in configuration if present
      def load_configuration!
        config_file_path = File.join(local.gitpusshuten_dir, 'nginx', 'config.yml')
        if File.exist?(config_file_path)
          GitPusshuTen::Log.message "Loading configuration from #{y(File.join(local.gitpusshuten_dir, 'nginx', 'config.yml'))}."
          config = YAML::load(File.read(config_file_path))
          @installation_dir         = config[:installation_dir]
          @configuration_directory  = config[:configuration_directory]
          @configuration_file       = config[:configuration_file]
        end
      end

    end
  end
end