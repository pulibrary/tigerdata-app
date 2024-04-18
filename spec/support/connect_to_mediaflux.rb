# frozen_string_literal: true

# Allow real connections to the Mediaflux server when a test is configured with
# connect_to_mediaflux: true
RSpec.configure do |config|
  config.before(:each) do |ex|
    if ex.metadata[:connect_to_mediaflux]
      @original_api_host = Rails.configuration.mediaflux["api_host"]
      Rails.configuration.mediaflux["api_host"] = "0.0.0.0"
      # Ensure the latest mediaflux schema has been loaded before running the tests
      require "rake"
      Rails.application.load_tasks
      Rake::Task["schema:create"].invoke
    end
  end

  config.after(:each) do |ex|
    if ex.metadata[:connect_to_mediaflux]
      Rails.configuration.mediaflux["api_host"] = @original_api_host
    end
  end
end
