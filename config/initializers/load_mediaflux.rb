# frozen_string_literal: true
module Tigerdata
  class Application < Rails::Application
    config.mediaflux = config_for(:mediaflux)
  end
end
