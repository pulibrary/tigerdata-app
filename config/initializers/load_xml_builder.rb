# frozen_string_literal: true
module PdcDescribe
  class LoadXmlBuilderConfig < Rails::Application
    config.xml_builder = YAML.load_file(Rails.root.join("config", "xml_builder.yml"), aliases: true, symbolize_names: true)
  end
end
