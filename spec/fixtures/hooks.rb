perform_on :staging do
  pre :remove_output do
    run 'rm -rf output'
  end

  post :render_output do
    run 'rake render:output'
  end

  post :restart_nginx_and_passenger do
    run '/etc/init.d/nginx stop'
    run 'sleep 1'
    run '/etc/init.d/nginx start'
    run 'mkdir tmp'
    run 'touch tmp/restart.txt'
  end
  
  post :ensure_correct_branch do
    run 'git commit -am "Commit and Ensuring"'
    run 'git checkout master'
  end
end

perform_on :production do
  pre :maintenance_on do
    run 'mv public/maintenance_off.html public/maintenance.html'
  end
  
  pre :clean_up_local do
    run 'rake remove:trash'
  end
  
  post :update_vhost do
    run 'webserver update vhost'
    run 'webserver restart'
  end  
end