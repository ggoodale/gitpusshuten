##
# Git Pusshu Ten - Configuration
#
# Here you specify all your environments. Most people will be
# satisfied with just 2: "staging" and "production". These are included
# in this configuration template. If you need more, feel free to add more.
#
# For more information, visit: http://gitpusshuten.com/configuration

pusshuten :staging, 'My Application' do

  authorize do |a|
    a.user      = 'gitpusshuten'
    a.password  = 'mypassword'
    a.ip        = '123.45.678.910'
    a.port      = '22'
  end

  git do |g|
    g.path = '/var/applications/'
  end

end

pusshuten :production, 'My Application' do

  authorize do |a|
    a.user      = 'gitpusshuten'
    a.password  = 'mypassword'
    a.ip        = '123.45.678.910'
    a.port      = '22'
  end
  
  git do |g|
    g.path = '/var/applications/'
  end

end