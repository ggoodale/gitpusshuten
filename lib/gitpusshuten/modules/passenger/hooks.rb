post 'Restart Passenger for Application' do
  run "mkdir -p tmp"
  run "touch tmp/restart.txt"
end