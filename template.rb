require "fileutils"
require "shellwords"


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

def add_gems
  gem 'data-confirm-modal', '~> 1.6.2'
  gem 'devise', '~> 4.4.3'
  gem 'devise-bootstrapped', github: 'excid3/devise-bootstrapped', branch: 'bootstrap4'
  gem 'devise_masquerade', '~> 0.6.0'
  gem 'font-awesome-sass', '~> 4.7'
  gem 'gravatar_image_tag', github: 'mdeering/gravatar_image_tag'
  gem 'jquery-rails', '~> 4.3.1'
  gem 'bootstrap', '~> 4.0.0.beta'
  gem 'webpacker', '~> 3.0'
  gem 'foreman', '~> 0.84.0'
  gem_group :development, :test do
    gem 'rspec-rails', '~> 3.6.0'
    gem 'factory_girl_rails', '~> 4.8.0'
    gem 'spring-commands-rspec'
  end

  gem_group :test do
    gem 'shoulda-matchers', '~> 3.1'
  end
end

def set_application_name
  # Ask user for application name
  application_name = ask("What is the name of your application? Default: QuickStart")

  # Checks if application name is empty and add default Jumpstart.
  application_name = application_name.present? ? application_name : "QuickStart"

  # Add Application Name to Config
  environment "config.application_name = '#{application_name}'"

  # Announce the user where he can change the application name in the future.
  puts "Your application name is #{application_name}. You can change this later on: ./config/application.rb"
end

def add_users
  # Install Devise
  generate "devise:install"

  # Configure Devise
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'
  route "root to: 'home#index'"

  # Devise notices are installed via Bootstrap
  generate "devise:views:bootstrapped"

  # Create Devise User
  generate :devise, "User",
           "name",
           "admin:boolean"

  # Set admin default to false
  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end

  requirement = Gem::Requirement.new("> 5.2")
  rails_version = Gem::Version.new(Rails::VERSION::STRING)

  if requirement.satisfied_by? rails_version
    gsub_file "config/initializers/devise.rb",
      /  # config.secret_key = .+/,
      "  config.secret_key = Rails.application.credentials.secret_key_base"
  end

  # Add Devise masqueradable to users
  inject_into_file("app/models/user.rb", "masqueradable, :", after: "devise :")
end

def add_bootstrap
  # Remove Application CSS
  run "rm app/assets/stylesheets/application.css"

  # Add Bootstrap JS
  insert_into_file(
    "app/assets/javascripts/application.js",
    "\n//= require jquery\n//= require popper\n//= require bootstrap\n//= require data-confirm-modal",
    after: "//= require rails-ujs"
  )
end

def copy_templates
  directory "app", force: true
  directory "config", force: true
  directory "lib", force: true
  directory "spec/models", force: true
  directory "spec/factories", force: true

  route "get '/terms', to: 'home#terms'"
  route "get '/privacy', to: 'home#privacy'"
end

def add_webpack
  rails_command "webpacker:install"
end

def add_foreman
  copy_file "Procfile"
end

def stop_spring
  run "spring stop"
end

def add_rspec
  generate "rspec:install"
  insert_into_file(
    ".rspec",
    "\n--format documentation\n",
    after: "--require spec_helper"
  )
  append_to_file(
    "spec/rails_helper.rb",
    "\n\n Shoulda::Matchers.configure do |config|\n    config.integrate do |with|\n     with.test_framework :rspec\n     with.library :rails\n    end\n end"
  )
  insert_into_file(
    "config/application.rb",
    "\n\n    config.generators do |g|\n     g.test_framework :rspec,\n     request_specs: false,\n     view_specs: false,\n     routing_specs: false,\n     helper_specs: false\n    end",
    after: "config.load_defaults 5.2"
  )
  run "bundle exec spring binstub rspec"
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

  copy_templates

  # Migrate
  rails_command "db:create:all"
  rails_command "db:migrate"
  rails_command "db:migrate", env: 'test'

  # Migrations must be done before this


  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
