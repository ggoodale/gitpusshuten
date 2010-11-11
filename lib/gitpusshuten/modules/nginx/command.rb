module GitPusshuTen
  module Commands
    class Nginx < GitPusshuTen::Commands::Base
      description "[Module] NginX commands."
      usage       "nginx <command> for <environment>"
      example     "nginx setup for staging                  # Sets up a managable vhost environment."
      example     "nginx update-configuration for staging   # Only for Passenger users, when updating Ruby/Passenger versions."
      example     "nginx create-vhost for production        # Creates a local vhost template for the specified environment."
      example     "nginx delete-vhost for production        # Deletes the remote vhost for the specified environment."
      example     "nginx upload-vhost for staging           # Uploads your local vhost to the server for the specified environment."
      example     "nginx download-vhost for production      # Downloads the remote vhost from the specified environment."
      example     "nginx start for staging                  # Starts NginX."
      example     "nginx stop for production                # Stops NginX."
      example     "nginx restart for production             # Restarts NginX."
      example     "nginx reload for production              # Reloads NginX."

      ##
      # NginX specific attributes/arguments
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
      # Performs the NginX command
      def perform!
        if respond_to?("perform_#{command}!")
          send("perform_#{command}!")
        else
          GitPusshuTen::Log.error "Unknown Nginx command: <#{y(command)}>"
          GitPusshuTen::Log.error "Run #{y('gitpusshuten help nginx')} for a list nginx commands."
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
        GitPusshuTen::Log.message "Reloading Nginx Configuration."
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
        # Downloads the NginX configuration file to tmp dir
        e.scp_as_root(:download, @configuration_file, local.tmp_dir)
        @configuration_file_name = @configuration_file.split('/').last
        
        ##
        # Set the path to the downloaded file
        local_file = File.join(local.tmp_dir, @configuration_file_name)
        
        if not File.read(local_file).include?('include vhosts/*;')
          GitPusshuTen::Log.message "Configuring NginX configuration file."
          
          ##
          # Inject the 'include vhosts/*'
          contents = File.read(local_file).sub(/http(\s|\t|\n){0,}\{/, "http {\n\s\s\s\sinclude vhosts/*;\n")
          File.open(local_file, 'w') do |file|
            file << contents
          end
          
          ##
          # Make a backup of the old nginx.conf
          GitPusshuTen::Log.message "Creating a backup of old NginX configuration file."
          e.execute_as_root("cp '#{@configuration_file}' '#{@configuration_file}.backup.#{Time.now.to_i}'")
          
          ##
          # Upload the file back
          GitPusshuTen::Log.message "Updating NginX configuration file."
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
        # Create NginX directory
        # Create NginX vhost file (if it doesn't already exist)
        # Create or Overwrite NginX config file that stores the vhosts directory
        create_vhost_template_file!
        
        ##
        # Writes the installation paths to a YAML file
        config_file = File.join(local.gitpusshuten_dir, 'nginx', "config.yml")
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
      def perform_upload_vhost!
        load_configuration!
        find_correct_paths!
        
        vhost_file = File.join(local.gitpusshuten_dir, 'nginx', "#{e.name}.vhost")
        if File.exist?(vhost_file)
          GitPusshuTen::Log.message "Uploading #{y(vhost_file)} to " +
          y(File.join(@configuration_directory, 'vhosts', "#{e.sanitized_app_name}.#{e.name}.vhost!"))
          
          Spinner.return :message => "Uploading vhost.." do
            e.scp_as_root(:upload, vhost_file, File.join(@configuration_directory, 'vhosts', "#{e.sanitized_app_name}.#{e.name}.vhost"))
            g("Finished uploading!")
          end
          
          perform_reload!
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
          perform_reload!
        else
          GitPusshuTen::Log.message "#{y(vhost_file)} does not exist."
          exit
        end
      end

      ##
      # Creates a vhost
      def perform_create_vhost!
        create_vhost_template_file!
      end

      ##
      # Performs the Update Configuration command
      # This is particularly used when you change Passenger or Ruby versions
      # so these are updated in the nginx.conf file.
      def perform_update_configuration!
        load_configuration!
        find_correct_paths!
        
        GitPusshuTen::Log.message "Checking the #{y(@configuration_file)} for current Passenger configuration."
        config_contents = e.execute_as_root("cat '#{@configuration_file}'")
        if not config_contents.include? 'passenger_root' or not config_contents.include?('passenger_ruby')
          GitPusshuTen::Log.error "Could not find Passenger configuration, has it ever been set up?"
          exit
        end
        
        GitPusshuTen::Log.message "Checking if Passenger is installed under the #{y('default')} Ruby."
        if not e.installed?('passenger')
          GitPusshuTen::Log.message "Passenger isn't installed for the current Ruby"
          Spinner.return :message => "Installing latest Phusion Passenger Gem.." do
            e.execute_as_root('gem install passenger --no-ri --no-rdoc')
            g("Done!")
          end
        end
        
        Spinner.return :message => "Finding current Phusion Passenger Gem version..." do
          if e.execute_as_root('passenger-config --version') =~ /(\d+\.\d+\..+)/
            @passenger_version = $1.chomp.strip
            g('Found!')
          else
            r('Could not find the current Passenger version.')
          end
        end
        
        exit if @passenger_version.nil?
        
        Spinner.return :message => "Finding current Ruby version for the current Phusion Passenger Gem.." do
          if e.execute_as_root('passenger-config --root') =~ /\/usr\/local\/rvm\/gems\/(.+)\/gems\/passenger-.+/
            @ruby_version = $1.chomp.strip
            g('Found!')
          else
            r("Could not find the current Ruby version under which the Passenger Gem has been installed.")
          end
        end
        
        exit if @ruby_version.nil?
        
        puts <<-INFO


  [Detected Versions]

    Ruby Version:               #{@ruby_version}
    Phusion Passenger Version:  #{@passenger_version}


        INFO
        
        GitPusshuTen::Log.message "NginX will now be configured to work with the above versions. Is this correct?"
        exit unless yes?
        
        ##
        # Checks to see if Passengers WatchDog is available in the current Passenger gem
        # If it is not, then Passenger needs to run the "passenger-install-nginx-module" so it gets installed
        if not e.directory?("/usr/local/rvm/gems/#{@ruby_version}/gems/passenger-#{@passenger_version}/agents")
          GitPusshuTen::Log.message "Phusion Passenger has not yet been installed for this Ruby's Passenger Gem."
          GitPusshuTen::Log.message "You need to reinstall/update #{y('NginX')} and #{y('Passenger')} to proceed with the configuration.\n\n"
          GitPusshuTen::Log.message "Would you like to reinstall/update #{y('NginX')} and #{y('Phusion Passenger')} #{y(@passenger_version)} for #{y(@ruby_version)}?"
          GitPusshuTen::Log.message "NOTE: Your current #{y('NginX')} configuration will #{g('not')} be lost. This is a reinstall/update that #{g('does not')} remove your NginX configuration."
          
          if yes?
            Spinner.return :message => "Ensuring #{y('Phusion Passenger')} and #{y('NginX')} dependencies are installed.." do
              e.execute_as_root("aptitude update; aptitude install -y build-essential libcurl4-openssl-dev libcurl4-gnutls-dev bison openssl libreadline5 libreadline5-dev curl git zlib1g zlib1g-dev libssl-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev")
              g("Done!")
            end
            
            GitPusshuTen::Log.message "Installing NginX with the Phusion Passenger Module."
            Spinner.return :message => "Installing, this may take a while.." do
              e.execute_as_root("passenger-install-nginx-module --auto --auto-download --prefix='#{@installation_dir}'")
              g("Done!")
            end
          else
            exit
          end
        end
        
        ##
        # Creates a tmp dir
        local.create_tmp_dir!
        
        ##
        # Downloads the NGINX configuration file to tmp dir
        GitPusshuTen::Log.message "Updating NginX configuration file."
        Spinner.return :message => "Configuring NginX.." do
          e.scp_as_root(:download, @configuration_file, local.tmp_dir)
          @configuration_file_name = @configuration_file.split('/').last
          
          local_configuration_file = File.join(local.tmp_dir, @configuration_file_name)
          update = File.read(local_configuration_file)
          update.sub! /passenger_root \/usr\/local\/rvm\/gems\/(.+)\/gems\/passenger\-(.+)\;/,
                      "passenger_root /usr/local/rvm/gems/#{@ruby_version}/gems/passenger-#{@passenger_version};"
          
          update.sub! /passenger_ruby \/usr\/local\/rvm\/wrappers\/(.+)\/ruby\;/,
                      "passenger_ruby /usr/local/rvm/wrappers/#{@ruby_version}/ruby;"
          
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
          
          g("Done!")
        end
        
        GitPusshuTen::Log.message "NginX configuration file has been updated!"
        GitPusshuTen::Log.message "#{y(@configuration_file)}\n\n"
        
        GitPusshuTen::Log.warning "If you changed Ruby versions, be sure that all the gems for your applications are installed.\n\n"
        
        GitPusshuTen::Log.warning "If you only updated #{y('Phusion Passenger')} and did not change #{y('Ruby versions')}"
        GitPusshuTen::Log.warning "then you should be able to just restart #{y('NginX')} right away since all application gems should still be in tact.\n\n"
        
        GitPusshuTen::Log.message "Run the following command to restart #{y('NginX')} and have the applied updates take effect:"
        GitPusshuTen::Log.message "#{y("gitpusshuten nginx restart for #{e.name}")}"
      end

      def perform_download_vhost!
        load_configuration!
        find_correct_paths!
        
        remote_vhost = File.join(@configuration_directory, "vhosts", "#{e.sanitized_app_name}.#{e.name}.vhost")
        if not e.file?(remote_vhost)
          GitPusshuTen::Log.error "There is no vhost currently present in #{y(remote_vhost)}."
          exit
        end
        
        local_vhost = File.join(local.gitpusshuten_dir, 'nginx', "#{e.name}.vhost")
        if File.exist?(local_vhost)
          GitPusshuTen::Log.warning "#{y(local_vhost)} already exists. Do you want to overwrite it?"
          exit unless yes?
        end
        
        Spinner.return :message => "Downloading vhost.." do
          e.scp_as_root(:download, remote_vhost, local_vhost)
          g("Finished downloading!")
        end
        GitPusshuTen::Log.message "You can find the vhost in: #{y(local_vhost)}."
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
        GitPusshuTen::Log.message "Confirming NginX installation directory location."
        while not @installation_dir_found
          if not e.directory?(@installation_dir)
            GitPusshuTen::Log.warning "Could not find NginX in #{y(@installation_dir)}."
            GitPusshuTen::Log.message "Please provide the path to the installation directory."
            @installation_dir = ask('')
          else
            GitPusshuTen::Log.message "NginX installation directory found in #{y(@installation_dir)}!"
            @installation_dir_found = true
          end
        end
        
        GitPusshuTen::Log.message "Confirming NginX configuration file location."
        @configuration_file = File.join(@installation_dir, "conf", "nginx.conf") if @configuration_file.nil?
        while not @configuration_file_found
          if not environment.file?(@configuration_file)
            GitPusshuTen::Log.warning "Could not find the NginX configuration file in #{y(@configuration_file)}."
            GitPusshuTen::Log.message "Please provide the (full/absolute) path to the NginX configuration file. (e.g. #{y(File.join(@installation_dir, "conf", "nginx.conf"))})"
            @configuration_file = ask('')
          else
            GitPusshuTen::Log.message "NginX configuration file found in #{y(@configuration_file)}!"
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

      ##
      # Creates a vhost template file if it doesn't already exist.
      def create_vhost_template_file!
        local.execute("mkdir -p '#{File.join(local.gitpusshuten_dir, 'nginx')}'")
        vhost_file  = File.join(local.gitpusshuten_dir, 'nginx', "#{e.name}.vhost")
        
        create_file = true
        if File.exist?(vhost_file)
          GitPusshuTen::Log.warning "#{y(vhost_file)} already exists, do you want to overwrite it?"
          create_file = yes?
        end
        
        if create_file
          File.open(vhost_file, 'w') do |file|
            file << "server {\n"
            file << "\s\slisten 80;\n"
            file << "\s\sserver_name mydomain.com www.mydomain.com;\n"
            file << "\s\sroot #{e.app_dir}/public;\n"
            file << "\s\s# passenger_enabled on; # For Phusion Passenger users\n"
            file << "}\n"
          end
          GitPusshuTen::Log.message "The vhost has been created in #{y(vhost_file)}."
        end
        
      end

    end
  end
end