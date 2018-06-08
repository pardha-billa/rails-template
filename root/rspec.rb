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
