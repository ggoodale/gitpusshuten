pusshuten :staging, 'RSpec Staging Example Application' do
  
  authorize do |a|
    a.user      = 'git'
    a.password  = 'testtest'
    a.ip        = '123.45.678.910'
    a.port      = '20'
  end
  
  git do |g|
    g.path = '/var/apps/'
  end
  
  modules do |m|
    m.add :nginx
    m.add :passenger
    m.add :active_record
  end
  
end

pusshuten :production, 'RSpec Production Example Application' do
  
end