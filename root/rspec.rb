def add_rspec
  generate "rspec:install"
  insert_into_file(
    ".rspec",
    "\n--format documentation\n",
    after: "--require spec_helper"
  )
  append_to_file(
    "spec/rails_helper.rb",
    shoulda_config
  )
  insert_into_file(
    "config/application.rb",
    rspec_generators_config,
    after: "class Application < Rails::Application"
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

def shoulda_config
 <<-HEREDOC

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
HEREDOC
end
