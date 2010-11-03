module GitPusshuTen
  class Environment
    
    ##
    # Stores the configuration
    attr_accessor :configuration
    
    def initialize(configuration)
      @configuration = configuration
    end
    
  end
end