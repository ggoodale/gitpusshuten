post "Install dependencies (Bundler)" do
  run "bundle install --without development test"
end