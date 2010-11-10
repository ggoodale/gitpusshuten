# encoding: utf-8
module GitPusshuTen
  module Commands
    class Rvm < GitPusshuTen::Commands::Base
      description "[Module] Ruby Version Manager (RVM) commands."
      usage       "rvm <command> for <environment>"
      example     "rvm install for staging                # Installs RVM (system wide)."
      example     "rvm update for staging                 # Updates RVM."
      example     "rvm list for staging                   # Lists installed Rubies under RVM."
      example     "rvm install-ruby for production        # Installs one of the available Ruby versions."
      example     "rvm uninstall-ruby for production      # Uninstalls an installed Ruby under RVM."
      example     "rvm remove-ruby for production         # Uninstalls and removes the Ruby's complete source from RVM."
      example     "rvm set-default-ruby for production    # Sets the system wide default Ruby."
      example     "                                         This is required if you want to change the Ruby version"
      example     "                                         for your Ruby applications running Passenger."

      ##
      # Passenger specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the RVM command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
        
        @command = @command.underscore
      end

      ##
      # Performs the RVM command
      def perform!
        if respond_to?("perform_#{command}!")
          send("perform_#{command}!")
        else
          GitPusshuTen::Log.error "Unknown RVM command: <#{y(command)}>"
          GitPusshuTen::Log.error "Run #{y('gitpusshuten help rvm')} for a list rvm commands."
        end
      end

      def perform_install!
        GitPusshuTen::Log.message "Installing Ruby Version Manager (#{y('RVM')})!"
        
        GitPusshuTen::Log.message "Which Ruby would you like to install and use as your default Ruby Interpreter?"
        ruby_version = choose_ruby_version!
        GitPusshuTen::Log.message "Going to install #{y(ruby_version)} after the #{y('RVM')} installation finishes."
        
        ##
        # Update aptitude and install git/curl/wget
        GitPusshuTen::Log.message "Updating package list and installing #{y('RVM')} requirements."
        Spinner.installing do
          e.execute_as_root("aptitude update; aptitude install -y git-core curl wget;")
        end
        
        ##
        # Install RVM (system wide)
        GitPusshuTen::Log.message "Starting #{y('RVM')} installation."
        Spinner.installing do
          e.execute_as_root("bash < <( curl -L http://bit.ly/rvm-install-system-wide )")
        end
        
        ##
        # Download Git Packages and add the rvm load snippet into /etc/profile
        if not e.execute_as_root("cat /etc/profile").include?('source "/usr/local/rvm/scripts/rvm"')
          GitPusshuTen::Log.message "Downloading Gitプッシュ点 packages and configuring /etc/profile."
          Spinner.installing do
            e.download_packages!("$HOME", :root)
            e.execute_as_root("cd $HOME; cat gitpusshuten-packages/modules/rvm/profile >> /etc/profile")
            e.clean_up_packages!("$HOME", :root)
          end
        end
        
        ##
        # Create a .bashrc in $HOME to load /etc/profile for non-interactive sessions
        if not e.execute_as_root("cat $HOME/.bashrc").include?('source /etc/profile')
          GitPusshuTen::Log.message "Configuring .bashrc file to load /etc/profile for non-interactive sessions."
          Spinner.installing do
            e.execute_as_root("echo 'source /etc/profile' >> $HOME/.bashrc; source $HOME/.bashrc")
          end
        end
        
        ##
        # Install required packages for installing Ruby
        GitPusshuTen::Log.message "Instaling the Ruby Interpreter dependency packages."
        Spinner.installing do
          e.execute_as_root("aptitude install -y build-essential bison openssl libreadline5 libreadline5-dev curl git zlib1g zlib1g-dev libssl-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev")
        end
        
        ##
        # Install a Ruby version
        GitPusshuTen::Log.message "Installing #{y(ruby_version)} with #{y('RVM')}."
        Spinner.installing_a_while do
          e.execute_as_root("rvm install #{ruby_version}")
        end
        
        ##
        # Set the Ruby version as the default Ruby
        GitPusshuTen::Log.message "Making #{y(ruby_version)} the default Ruby."
        e.execute_as_root("rvm use #{ruby_version} --default")
        
        GitPusshuTen::Log.message "Finished!"
      end
      
      ##
      # Performs an update for RVM
      def perform_update!
        GitPusshuTen::Log.message "Updating RVM."
        GitPusshuTen::Log.message "Would you like to get the latest stable, or bleeding edge version?"
        options = choose do |menu|
          menu.prompt = ''
          menu.choice('latest stable') { nil      }
          menu.choice('bleeding edge') { '--head' }
        end
        Spinner.updating do
          puts e.execute_as_root("rvm update #{options}")
        end
      end
      
      ##
      # Displays a list of installed gems
      def perform_list!
        GitPusshuTen::Log.message "Getting a list of installed Rubies."
        Spinner.loading do
          puts e.execute_as_root("rvm list")
        end
        GitPusshuTen::Log.message "The ( #{y("=>")} ) arrow indicates which Ruby version is currently being used."
      end
      
      ##
      # Installs a Ruby version with RVM
      def perform_install_ruby!
        perform_list!
        
        GitPusshuTen::Log.message "Which Ruby version would you like to install?"
        ruby_version = choose_ruby_version!
        
        GitPusshuTen::Log.message "Would you like to make #{y(ruby_version)} your default Ruby?"
        yes? ? make_default = true : make_default = false
        
        Spinner.installing do
          e.execute_as_root("rvm install #{ruby_version}")
        end
        
        if make_default
          GitPusshuTen::Log.message "Setting #{y(ruby_version)} as the system wide default Ruby."
          e.execute_as_root("rvm use #{ruby_version} --default")
        end
      end
      
      ##
      # Uninstalls a Ruby version
      def perform_uninstall_ruby!
        perform_list!
        
        GitPusshuTen::Log.message "Which Ruby version would you like to uninstall?"
        ruby_version = choose_ruby_version!
        
        Spinner.updating :complete => nil, :return => true do
          if not e.execute_as_root("rvm uninstall #{ruby_version}") =~ /has already been removed/
            g("Ruby version #{ruby_version} has been uninstalled.")
          else
            r("Ruby version #{ruby_version} has already been removed.")
          end
        end
      end
      
      ##
      # Remove a Ruby version
      def perform_remove_ruby!
        perform_list!
        
        GitPusshuTen::Log.message "Which Ruby version would you like to remove?"
        ruby_version = choose_ruby_version!
        
        Spinner.updating :complete => nil, :return => true do
          if not e.execute_as_root("rvm remove #{ruby_version}") =~ /is already non existent/
            g("Ruby version #{ruby_version} has been removed.")
          else
            r("Ruby version #{ruby_version} is already non existent.")
          end
        end
      end
      
      ##
      # Change the default Ruby on the server
      def perform_set_default_ruby!
        perform_list!
        
        GitPusshuTen::Log.message "Which Ruby version would you like to make the system wide default?"
        ruby_version = choose_ruby_version!
        
        Spinner.return :message => "Changing system wide default Ruby to #{y(ruby_version)}" do
          if not e.execute_as_root("rvm use #{ruby_version} --default") =~ /not installed/
            @succeeded = true
            g("Ruby version #{ruby_version} is now set as the system wide default.")
          else
            r("Could not set #{ruby_version} as default")
          end
        end
        
        if @succeeded
          GitPusshuTen::Log.message("If you want to use #{y(ruby_version)} for your Ruby applications with Passenger")
          GitPusshuTen::Log.message("you must update your #{y('NginX')} configuration. To do this, run the following command:")
          GitPusshuTen::Log.message(y("gitpusshuten nginx update-configuration for #{e.name}"))
          GitPusshuTen::Log.message("And follow any further instructions given.")
        end
      end
      
      ##
      # Prompts the user to choose a Ruby to install
      def choose_ruby_version!
        choose do |menu|
          menu.prompt = ''
          
          %w[ruby-1.8.6 ruby-1.8.7 ruby-1.9.1 ruby-1.9.2 ].each do |mri|
            menu.choice(mri)
          end
          
          %w[ree-1.8.6 ree-1.8.7].each do |ree|
            menu.choice(ree)
          end
        end
      end
      
    end
  end
end