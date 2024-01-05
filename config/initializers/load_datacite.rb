# frozen_string_literal: true
module PdcDescribe
  class Application < Rails::Application
    config.datacite = config_for(:datacite)
  end
end
