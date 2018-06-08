def add_webpack
  rails_command "webpacker:install"
end

def add_foreman
  copy_file "Procfile"
end

def stop_spring
  run "spring stop"
end


