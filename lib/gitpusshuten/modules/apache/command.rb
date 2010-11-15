module GitPusshuTen
  module Commands
    class Apache < GitPusshuTen::Commands::Base
      description "[Module] Apache commands."
      usage       "apache <command> <for|from|to> <environment> (environment)"
      example     "gitpusshuten apache update-configuration for staging   # Only for Passenger users, when updating Ruby/Passenger versions."
      example     "gitpusshuten apache create-vhost for production        # Creates a local vhost template for the specified environment."
      example     "gitpusshuten apache delete-vhost from production       # Deletes the remote vhost for the specified environment."
      example     "gitpusshuten apache upload-vhost to staging            # Uploads your local vhost to the server for the specified environment."
      example     "gitpusshuten apache download-vhost from production     # Downloads the remote vhost from the specified environment."
      example     "gitpusshuten apache start staging environment          # Starts the Apache webserver."
      example     "gitpusshuten apache stop production environment        # Stops the Apache webserver."
      example     "gitpusshuten apache restart production environment     # Restarts the Apache webserver."
      example     "gitpusshuten apache reload production environment      # Reloads the Apache webserver."

      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
        
        @command = @command.underscore
        
        ##
        # Default Configuration
        @installation_dir         = "/etc/apache2"
        @configuration_directory = @installation_dir
        @configuration_file      = File.join(@configuration_directory, 'apache2.conf')
      end

      ##
      # Installs the Apache2 web server
      def perform_install!
        prompt_for_root_password!
        
        Spinner.return :message => "Installing Apache2 web server.." do
         e.install!('apache2')
          g('Done!')
        end
        message "Apache2 has been installed in #{y('/etc/apache2')}."
      end

      ##
      # Starts Apache
      def perform_start!
        message "Starting Apache."
        puts e.execute_as_root("/etc/init.d/apache2 start")
      end

      ##
      # Stops Apache
      def perform_stop!
        message "Stopping Apache."
        puts e.execute_as_root("/etc/init.d/apache2 stop")
      end

      ##
      # Restarts Apache
      def perform_restart!
        message "Restarting Apache."
        puts e.execute_as_root("/etc/init.d/apache2 restart")
      end

      ##
      # Reload Apache
      def perform_reload!
        message "Reloading Apache Configuration."
        puts e.execute_as_root("/etc/init.d/apache2 reload")
      end

      def perform_download_vhost!
        remote_vhost = File.join(@configuration_directory, "sites-enabled", "#{e.sanitized_app_name}.#{e.name}.vhost")
        if not e.file?(remote_vhost) #prompts root
          error "There is no vhost currently present in #{y(remote_vhost)}."
          exit
        end
        
        local.execute("mkdir -p #{File.join(local.gitpusshuten_dir, 'apache')}")
        local_vhost = File.join(local.gitpusshuten_dir, 'apache', "#{e.name}.vhost")
        if File.exist?(local_vhost)
          warning "#{y(local_vhost)} already exists. Do you want to overwrite it?"
          exit unless yes?
        end
        
        Spinner.return :message => "Downloading vhost.." do
          e.scp_as_root(:download, remote_vhost, local_vhost)
          g("Finished downloading!")
        end
        message "You can find the vhost in: #{y(local_vhost)}."
      end

      ##
      # Uploads a local vhost
      def perform_upload_vhost!        
        vhost_file = File.join(local.gitpusshuten_dir, 'apache', "#{e.name}.vhost")
        if File.exist?(vhost_file)
          message "Uploading #{y(vhost_file)} to " +
          y(File.join(@configuration_directory, 'sites-enabled', "#{e.sanitized_app_name}.#{e.name}.vhost!"))
          
          prompt_for_root_password!
          
          Spinner.return :message => "Uploading vhost.." do
            e.scp_as_root(:upload, vhost_file, File.join(@configuration_directory, 'sites-enabled', "#{e.sanitized_app_name}.#{e.name}.vhost"))
            g("Finished uploading!")
          end
          
          perform_restart!
        else
          error "Could not locate vhost file #{y(vhost_file)}."
          error "Download an existing one from your server with:"
          standard "\n\s\s#{y("gitpusshuten apache download-vhost for #{e.name}")}\n\n"
          error "Or create a new template by running:"
          standard "\n\s\s#{y("gitpusshuten apache create-vhost for #{e.name}")}\n\n"
          exit
        end
      end

      ##
      # Deletes a vhost
      def perform_delete_vhost!
        vhost_file = File.join(@configuration_directory, 'sites-enabled', "#{e.sanitized_app_name}.#{e.name}.vhost")
        if e.file?(vhost_file) # prompts root
          message "Deleting #{y(vhost_file)}!"
          e.execute_as_root("rm #{vhost_file}")
          perform_reload!
        else
          message "#{y(vhost_file)} does not exist."
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
      # so these are updated in the apache2.conf file.
      def perform_update_configuration!
        message "Checking the #{y(@configuration_file)} for current Passenger configuration."
        config_contents = e.execute_as_root("cat '#{@configuration_file}'") # prompts root
        if not config_contents.include? 'PassengerRoot' or not config_contents.include?('PassengerRuby') or not config_contents.include?('passenger_module')
          error "Could not find Passenger configuration, has it ever been set up?"
          exit
        end
        
        message "Checking if Passenger is installed under the #{y('default')} Ruby."
        if not e.installed?('passenger')
          message "Passenger isn't installed for the current Ruby"
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
        
        message "Apache will now be configured to work with the above versions. Is this correct?"
        exit unless yes?
        
        ##
        # Checks to see if Passengers WatchDog is available in the current Passenger gem
        # If it is not, then Passenger needs to run the "passenger-install-nginx-module" so it gets installed
        if not e.directory?("/usr/local/rvm/gems/#{@ruby_version}/gems/passenger-#{@passenger_version}/agents")
          message "Phusion Passenger has not yet been installed for this Ruby's Passenger Gem."
          message "You need to reinstall/update #{y('Apache')} and #{y('Passenger')} to proceed with the configuration.\n\n"
          message "Would you like to reinstall/update #{y('Apache')} and #{y('Phusion Passenger')} #{y(@passenger_version)} for #{y(@ruby_version)}?"
          message "NOTE: Your current #{y('Apache')} configuration will #{g('not')} be lost. This is a reinstall/update that #{g('does not')} remove your #{y('Apache')} configuration."
          
          if yes?
            Spinner.return :message => "Ensuring #{y('Phusion Passenger')} and #{y('Apache')} dependencies are installed.." do
              e.install!("build-essential libcurl4-openssl-dev bison openssl libreadline5 libreadline5-dev curl git-core zlib1g zlib1g-dev libssl-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev")
              e.install!("apache2-mpm-prefork apache2-prefork-dev libapr1-dev libaprutil1-dev")
              g("Done!")
            end
            
            message "Installing Apache with the Phusion Passenger Module."
            Spinner.return :message => "Installing, this may take a while.." do
              e.execute_as_root("passenger-install-apache2-module --auto")
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
        # Downloads the Apache configuration file to tmp dir
        message "Updating Phusion Passenger paths in the Apache Configuration."
        Spinner.return :message => "Configuring Apache.." do
          e.scp_as_root(:download, @configuration_file, local.tmp_dir)
          @configuration_file_name = @configuration_file.split('/').last
          
          local_configuration_file = File.join(local.tmp_dir, @configuration_file_name)
          update = File.read(local_configuration_file)
          
          update.sub! /LoadModule passenger_module \/usr\/local\/rvm\/gems\/(.+)\/gems\/passenger-(.+)\/ext\/apache2\/mod_passenger\.so/,
                      "LoadModule passenger_module /usr/local/rvm/gems/#{@ruby_version}/gems/passenger-#{@passenger_version}/ext/apache2/mod_passenger.so"
          
          update.sub! /PassengerRoot \/usr\/local\/rvm\/gems\/(.+)\/gems\/passenger-(.+)/,
                      "PassengerRoot /usr/local/rvm/gems/#{@ruby_version}/gems/passenger-#{@passenger_version}"
          
          update.sub! /PassengerRuby \/usr\/local\/rvm\/wrappers\/(.+)\/ruby/,
                      "PassengerRuby /usr/local/rvm/wrappers/#{@ruby_version}/ruby"
          
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
        
        message "Apache configuration file has been updated!"
        message "#{y(@configuration_file)}\n\n"
        
        warning "If you changed Ruby versions, be sure that all the gems for your applications are installed."
        warning "If you only updated #{y('Phusion Passenger')} and did not change #{y('Ruby versions')}"
        warning "then you should be able to just restart #{y('Apache')} right away since all application gems should still be in tact.\n\n"
        
        message "Run the following command to restart #{y('Apache')} and have the applied updates take effect:"
        standard "\n\s\s#{y("gitpusshuten apache restart for #{e.name}")}"
      end

      ##
      # Creates a vhost template file if it doesn't already exist.
      def create_vhost_template_file!
        local.execute("mkdir -p '#{File.join(local.gitpusshuten_dir, 'apache')}'")
        vhost_file  = File.join(local.gitpusshuten_dir, 'apache', "#{e.name}.vhost")
        
        create_file = true
        if File.exist?(vhost_file)
          warning "#{y(vhost_file)} already exists, do you want to overwrite it?"
          create_file = yes?
        end
        
        if create_file
          File.open(vhost_file, 'w') do |file|
            file << "<VirtualHost *:80>\n"
            file << "\s\sServerName mydomain.com\n"
            file << "\s\sServerAlias www.mydomain.com\n"
            file << "\s\sDocumentRoot #{e.app_dir}/public\n"
            file << "\s\s<Directory #{e.app_dir}/public>\n"
            file << "\s\s\s\sAllowOverride all\n"
            file << "\s\s\s\sOptions -MultiViews\n"
            file << "\s\s</Directory>\n"
            file << "</VirtualHost>\n"
          end
          message "The vhost has been created in #{y(vhost_file)}."
        end
      end

    end
  end
end