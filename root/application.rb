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


