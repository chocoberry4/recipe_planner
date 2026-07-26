source "https://rubygems.org"

gem "rails", "~> 8.0.3"

gem "active_model_serializers", "~> 0.10.15"
# Generates resized ActiveStorage variants (recipe thumbnails) via libvips,
# already installed in the Dockerfile - without this, an uploaded/imported
# image is served at its full original resolution everywhere, including tiny
# list/picker thumbnails.
gem "image_processing", "~> 1.2"
gem "bcrypt"
# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

gem "pg", "~> 1.6"
gem "puma", ">= 5.0"
gem "rack-cors"
gem "rubyzip", "~> 2.3", require: "zip"
gem "rubocop", require: false
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false
gem "kamal", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "vite_rails", "~> 3.0"

group :development, :test do
  gem "brakeman", "~> 8.0", require: false
  gem "bundler-audit", require: false
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "factory_bot_rails", require: false
  gem "faker"
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails", "~> 8.0.0"
  gem "pry"
end

group :development do
  gem "guard-rspec", require: false
end
