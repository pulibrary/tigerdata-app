# frozen_string_literal: true
require_relative "boot"

require "rails/all"
require_relative "lando_env"

# Require the gems listed in Gemfile, but only the default ones
# and those for the environment rails is running in
Bundler.require(:default, Rails.env)

module TigerDataApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # terminate the mediaflux session if the user logs out
    Warden::Manager.before_logout do |user, _auth, _opts|
      user.terminate_mediaflux_session
    end
  end
end
