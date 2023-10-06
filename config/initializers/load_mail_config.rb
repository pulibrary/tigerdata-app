# frozen_string_literal: true
module PdcDescribe
  class Application < Rails::Application
    config.tigerdata_mail = config_for(:mail)
  end
end
