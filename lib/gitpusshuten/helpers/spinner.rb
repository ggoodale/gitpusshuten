STDOUT.sync = true

class Spinner

  ##
  # Loadify Method
  #  * block of code you want to provide a loader for
  #
  # Options
  #  * :message  => 'Message to be displayed while processing'
  #  * :success  => 'Message to be displayed when true is returned from executed code'
  #  * :fail     => 'Message to be displayed when false is returned from the executed code'
  #  * :complete => 'Message to be displayed after processing, regardless of the returned value'
  #  * :return   => 'When set to true, it will display the returned value of the executed code' 
  def initialize(options = {}, &code)
  
    ##
    # Character to loop through (loader)
    characters = %w[| / - \\ | / - \\]
  
    ##
    # Create a new thread to run the provided block of code in
    thread = Thread.new do
      code.call
    end
  
    ##
    # Enter a while loop and stay in it until the thread
    # finished processing the provided code. This will display
    # and animate the loader meanwhile.
    while thread.alive?
      next_character = characters.shift
      message = "#{next_character} #{options[:message] || ''}"
      print message
      characters << next_character
      sleep 0.065
      print "\b" * message.length
    end
  
    ##
    # Extract the value from the dead thread
    returned_value = thread.value
  
    ##
    # Print Final Message
    print "#{options[:message]}  "
  
    ##
    # Print On Complete Message if options is set to true
    unless options[:complete].nil?
      print options[:complete]
      print " "
    end
  
    if not options[:success].nil? and returned_value
      print options[:success]
      print " "
    end
  
    if not options[:fail].nil? and not returned_value
      print options[:fail]
      print " "
    end
  
    ##
    # Prints the returned value from the code block
    # that was executed if set to true
    if options[:return]
      print returned_value
    end
    
    ##
    # Add a new line
    print "\n"
    
    ##
    # Return the value from the dead thread
    returned_value
  end

  def self.installing(&code)
    Spinner.new(:message => "Installing..", :complete => 'DONE'.color(:green), &code)
  end

  def self.installing_a_while(&code)
    Spinner.new(:message => "Installing, this may take a while..", :complete => 'DONE'.color(:green), &code)
  end

end