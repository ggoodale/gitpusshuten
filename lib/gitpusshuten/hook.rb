module GitPusshuTen
  class Hook

    ##
    # Stores the name of the performed hook
    attr_accessor :name

    ##
    # Stores the type of hook (pre or post)
    attr_accessor :type

    ##
    # Stores the (parsed) commands that need to be run
    attr_accessor :commands

    ##
    # Initializes a new hook
    # Takes a hash of parameters
    def initialize(options)
      @name     = options[:name]
      @type     = options[:type]
      @commands = options[:commands]
    end

  end
end