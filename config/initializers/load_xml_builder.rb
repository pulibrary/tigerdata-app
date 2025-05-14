# frozen_string_literal: true
module PdcDescribe
  class LoadXmlBuilderConfig < Rails::Application
    config.xml_builder = config_for(:xml_builder)
  end
end
