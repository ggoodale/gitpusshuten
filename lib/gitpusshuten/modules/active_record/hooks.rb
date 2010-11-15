post "Migrate Database (Active Record)" do
  run "rake db:create"
  run "rake db:migrate"
end