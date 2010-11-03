perform_on :staging, :production do
  pre :remove_output do
    run 'rm -rf output'
  end

  post :render_output do
    run 'rake render:output'
  end
end

perform_on :staging do
  post :clear_whitespace do
    run 'rake clear:whitespace'
    run 'rake flush'
  end
end

perform_on :production do
  pre :update_vhost do
    run 'webserver update vhost'
    run 'webserver restart'
  end
end