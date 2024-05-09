# frozen_string_literal: true

require "yaml"

module BannerHelper
  def banner_content
    @yaml_data = YAML.load_file("config/banner.yml")
    return false if @yaml_data[Rails.env].nil?
    @banner_title = @yaml_data[Rails.env]['title']
    @banner_body = @yaml_data[Rails.env]['body']
  end
end
