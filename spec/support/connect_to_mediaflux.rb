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
      # Clean out the namespace before running tests to avoid collisions
      user = User.new
      destroy_request = Mediaflux::NamespaceDestroyRequest.new(
        session_token: user.mediaflux_session,
        namespace: Rails.configuration.mediaflux[:api_root_ns]
      )
      destroy_request.destroy
      if destroy_request.error?
        puts "Error destroying the mediaflux root namespace #{destroy_request.response_error}" # allow the message to show in CI output
      end

      # then create it so it exists for any tests
      create_request = Mediaflux::NamespaceCreateRequest.new(
        session_token: user.mediaflux_session,
        namespace: Rails.configuration.mediaflux[:api_root_ns]
      )
      create_request.resolve
      if create_request.error?
        puts "Error creating the mediaflux root namespace #{create_request.response_error}" # allow the message to show in CI output
      end
    end
  rescue StandardError => namespace_error
    message = "Bypassing pre-test cleanup error, #{namespace_error.message}"
    puts message # allow the message to show in CI output
    Rails.logger.error(message)
  end

  config.after(:each) do |ex|
    if ex.metadata[:connect_to_mediaflux]
      Rails.configuration.mediaflux["api_host"] = @original_api_host
    end
  end
end
