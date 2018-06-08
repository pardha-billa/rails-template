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


