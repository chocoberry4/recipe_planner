source "https://rubygems.org"

gem "rails", "~> 8.1.1"

gem "bcrypt"
# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "vite_rails", "~> 3.0"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  gem 'rspec-rails', '~> 8.0.0'
end