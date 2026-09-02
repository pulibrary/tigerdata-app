# frozen_string_literal: true
source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 4.0.4"

gem "bootsnap", require: false
gem "bootstrap", "~> 5.2.0"
gem "cocina-models"
gem "csv"
gem "datacite"
gem "devise"
gem "dogstatsd-ruby"
gem "dry-operation"
gem "flipflop"
gem "google-protobuf", "~> 4.35" # 3.25 platform gems require ruby < 3.4; 4.x supports Ruby 4.0
gem "health-monitor-rails", "12.5.0"
gem "honeybadger"
gem "importmap-rails"
gem "jbuilder"
gem "kaminari"
gem "mini_racer"
gem "net-http-persistent"
gem "net-ldap"
gem "omniauth-cas", "~> 3.0"
gem "omniauth-entra-id"
gem "openssl", ">= 3.3.1"
gem "pg"
gem "psych"
gem "puma"
gem "rack", ">= 3.1.21"
gem "rails", "~> 8.1.3"
gem "redis", "~> 4.0"
gem "sassc-rails"
gem "sidekiq"
gem "sprockets-rails"
gem "stimulus-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[windows]
gem "uri", ">= 1.0.4"
gem "vite_rails"
gem "whenever", require: false

group :development, :test do
  gem "bcrypt_pbkdf"
  # RuboCop (via bixby) requires benchmark; it is no longer a default gem as of Ruby 4.0.
  gem "benchmark"
  gem "bixby"
  gem "bundle-audit", require: false
  gem "byebug"
  gem "capistrano-yarn"
  gem "ed25519"
  gem "factory_bot_rails", require: false
  gem "ffaker"
  gem "mutex_m", "~> 0.2.0"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec-rails"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  gem "rack-mini-profiler"

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
  gem "ruby-prof"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "stackprof", ">= 0.2.9", require: false
  gem "test-prof", "~> 1.0"
  gem "timecop"
  gem "webmock"
end

gem "yard", "~> 0.9.44", group: :development
