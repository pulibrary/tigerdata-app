# frozen_string_literal: true
module PdcDescribe
  class Application < Rails::Application
    config.default_sponsors = config_for(:default_sponsors)
  end
end
