# encoding: utf-8
module GitPusshuTen
  module Commands
    class Rvm < GitPusshuTen::Commands::Base
      description "[Module] Ruby Version Manager (RVM) commands."
      usage       "rvm <command> for <environment>"
      example     "rvm install for staging"

      ##
      # Passenger specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the RVM command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
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
        
        ##
        # Update apt-get and install git/curl/wget
        GitPusshuTen::Log.message "Updating package list and installing #{y('RVM')} requirements."
        Spinner.installing do
          e.execute_as_root("apt-get update; apt-get install -y git-core curl wget;")
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
        GitPusshuTen::Log.message "Installing Ruby 1.9.2 with #{y('RVM')}."
        Spinner.installing_a_while do
          e.execute_as_root("rvm install 1.9.2")
        end
        
        ##
        # Set the Ruby version as the default Ruby
        GitPusshuTen::Log.message "Making Ruby 1.9.2 the default system Ruby."
        e.execute_as_root("rvm use 1.9.2 --default")
        
        GitPusshuTen::Log.message "Finished!"
      end
      
    end
  end
end