# frozen_string_literal: true
source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.0"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0.4", ">= 7.0.4.2"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgres as the database for Active Record
gem "pg"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 5.6"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
# gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem "bootstrap", "~> 5.2.0"
gem "vite_rails"

# Single sign on
gem "devise"
gem "omniauth-cas", "~> 3.0"

gem "csv"
gem "datacite", github: "sul-dlss/datacite-ruby", branch: "main"
gem "dogstatsd-ruby"
gem "flipflop"
gem "google-protobuf", "~> 3.25"
gem "health-monitor-rails"
gem "honeybadger"
gem "mailcatcher"
gem "net-http-persistent"
gem "sidekiq"

gem "whenever", require: false
group :staging, :production do
  gem "ddtrace", require: "ddtrace/auto_instrument"
end

group :development, :test do
  gem "rspec-rails", "~> 6.0.0"

  gem "bixby"
  gem "byebug"
  gem "pry-rails"

  gem "bcrypt_pbkdf"
  gem "capistrano-yarn"
  gem "ed25519"
  gem "factory_bot_rails", require: false
  gem "ffaker"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  gem "capistrano", "~> 3.17", require: false
  gem "capistrano-passenger"
  gem "capistrano-rails", "~> 1.6", require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "axe-core-rspec"
  gem "capybara"
  gem "coveralls_reborn", require: false
  gem "rails-controller-testing"
  gem "rspec_junit_formatter"
  gem "rspec-retry"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "webmock"
  gem "yard"
end
