post "Migrate Database (Active Record)" do
  run "rake db:migrate RAILS_ENV=production"
end