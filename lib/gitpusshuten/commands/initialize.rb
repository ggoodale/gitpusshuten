# encoding: utf-8
module GitPusshuTen
  module Commands
    class Initialize < GitPusshuTen::Commands::Base
      description "Initializes Git Pusshu Ten (プッシュ点) with the working directory."
      usage       "gitpusshuten initialize"

      ##
      # Initialize specific attributes/arguments
      attr_accessor :working_directory

      ##
      # Initializes the Tag command
      def initialize(*objects)
        super
        
        @working_directory = Dir.pwd
      end

      ##
      # Performs the Tag command
      def perform!
        if may_initialize?
          copy_templates!
          GitPusshuTen::Log.message "Git Pusshu Ten (プッシュ点) initialized in: #{working_directory}!"
        else
          GitPusshuTen::Log.message "If you wish to initialize it elsewhere, please move into that directory and run " +
          "gitpusshuten initialize".color(:yellow) + " again."
        end
      end

      ##
      # Asks the user if Git Pusshu Ten may initialize the
      # working directory for Git Pusshu Ten
      def may_initialize?
        GitPusshuTen::Log.message "Would you like to initialize Git Pusshu Ten (プッシュ点) with #{working_directory}?"
        choose do |menu|
          menu.prompt = ''
          menu.choice('Yes') { true  }
          menu.choice('No')  { false }
        end
      end

      ##
      # Copies the "config.rb" and "hooks.rb" templates over
      # to the .gitpusshuten inside the working directory
      def copy_templates!
        %x[mkdir -p "#{working_directory}/.gitpusshuten"]
        Dir[File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'templates', '*.rb'))].each do |template|
          %x[cp "#{template}" "#{working_directory}/.gitpusshuten/#{template.split('/').last}"]
        end
      end

    end
  end
end
