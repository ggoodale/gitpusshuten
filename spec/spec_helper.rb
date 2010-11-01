require 'gitpusshuten'

RSpec.configure do |config|
  config.mock_with :mocha
end


##
# GitPusshuTen::Command Mock
module GitPusshuTen
  class Command
    class NonExistingCommand
      def initialize(cli, configuration); end
    end
  end
end