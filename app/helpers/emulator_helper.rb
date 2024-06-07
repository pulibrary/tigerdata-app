# frozen_string_literal: true

require "yaml"

module EmulatorHelper
  def emulator_content
    @yaml_data = YAML.load_file("config/emulator.yml")
    return false if @yaml_data[Rails.env].nil? || @yaml_data[Rails.env] == "production"
    return false unless current_page?("/")
    @emulator_title = @yaml_data[Rails.env]["title"]
    @emulator_body = @yaml_data[Rails.env]["body"]
  end
end
