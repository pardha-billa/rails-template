require "fileutils"
require "shellwords"

#---------------------------
# Adding gems to application
#---------------------------
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
    gem "factory_bot_rails", "~> 4.10.0"
    gem 'spring-commands-rspec'
  end

  gem_group :test do
    gem 'shoulda-matchers', '~> 3.1'
  end
end

#---------------------------
# Bootstrap the application
#---------------------------
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


#---------------------------
# Configure Rspec
#---------------------------
def add_rspec
  generate "rspec:install"
  insert_into_file(
    ".rspec",
    "\n--format documentation\n",
    after: "--require spec_helper"
  )
  insert_into_file(
    "config/application.rb",
    rspec_generators_config,
    after: "class Application < Rails::Application"
  )
  insert_into_file(
    "spec/rails_helper.rb",
    "\n   Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f  }",
    after: "require 'rspec/rails'"
  )
  run "bundle exec spring binstub rspec"
end

def rspec_generators_config
 <<-HEREDOC


    config.generators do |g|
      g.test_framework :rspec,
      request_specs: false,
      view_specs: false,
      routing_specs: false,
      helper_specs: false
    end

 HEREDOC
end

#---------------------------
# Configure Devise for authentication
#---------------------------
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

#---------------------------
# Server Confiuration
#---------------------------
def add_webpack
  rails_command "webpacker:install"
end

def add_foreman
  copy_file "Procfile"
end

def stop_spring
  run "spring stop"
end

#---------------------------
# Application Specific Settings
#---------------------------
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

def copy_application_templates
  directory "app", force: true
  directory "config", force: true
  directory "lib", force: true
  directory "spec/models", force: true
  directory "spec/factories", force: true
  directory "spec/support", force: true

  route "get '/terms', to: 'home#terms'"
  route "get '/privacy', to: 'home#privacy'"
end



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
