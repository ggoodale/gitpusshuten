# encoding: utf-8
module GitPusshuTen
  module Commands
    class Version < GitPusshuTen::Commands::Base
      description "Displays the current version of Git Pusshu Ten (プッシュ点)."

      ##
      # Initializes the Version command
      def initialize(*objects)
        super
      end

      ##
      # Performs the Version command
      def perform!
        puts "Git Pusshu Ten (プッシュ点) version #{GitPusshuTen::VERSION}"
      end

    end
  end
end