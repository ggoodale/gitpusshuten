##
# Git Pusshu Ten - Configuration
#
# Here you specify all your environments. Most people will be
# satisfied with just 2: "staging" and "production". These are included
# in this configuration template. If you need more, feel free to add more.
#
# For more information, visit: http://gitpusshuten.com/configuration


##
# Example of configuring both a staging and production environment
pusshuten 'My Application', :staging, :production do

  authorize do |a|
    a.user      = 'gitpusshuten'
    a.password  = 'mypassword'
    a.ip        = '123.45.678.90'
    a.port      = '22'
  end

  applications do |a|
    a.path = '/var/applications/'
  end

end

##
# Example of only configuring a staging environment
# pusshuten 'My Application', :staging do
# 
#   authorize do |a|
#     a.user      = 'gitpusshuten'
#     a.password  = 'mypassword'
#     a.ip        = '123.45.678.90'
#     a.port      = '22'
#   end
# 
#   applications do |a|
#     a.path = '/var/applications/'
#   end
# 
# end

##
# Example of only configuring a production environment
# pusshuten 'My Application', :production do
# 
#   authorize do |a|
#     a.user      = 'gitpusshuten'
#     a.password  = 'mypassword'
#     a.ip        = '123.45.678.90'
#     a.port      = '22'
#   end
#   
#   applications do |a|
#     a.path = '/var/applications/'
#   end
# 
# end
