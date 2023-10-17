# frozen_string_literal: true
module PdcDescribe
  class Application < Rails::Application
    config.default_mediaflux_admins = config_for(:default_mediaflux_admins)
  end
end
