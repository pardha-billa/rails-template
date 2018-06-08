require "fileutils"
require "shellwords"
require_relative "root/gems.rb"
require_relative "root/bootstrap.rb"
require_relative "root/rspec.rb"
require_relative "root/devise.rb"
require_relative "root/server.rb"
require_relative "root/application.rb"

def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("rails-template-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/pardha-billa/rails-template.git",
      tempdir
    ].map(&:shellescape).join(" ")

    if (branch = __FILE__[%r{rails-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

# Main setup
add_template_repository_to_source_path
add_gems

after_bundle do
  set_application_name
  stop_spring
  add_rspec
  stop_spring
  add_users
  add_bootstrap
  add_foreman
  add_webpack

  copy_application_templates

  # Migrate
  rails_command "db:create:all"
  rails_command "db:migrate"
  rails_command "db:migrate", env: 'test'

  # Migrations must be done before this
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
