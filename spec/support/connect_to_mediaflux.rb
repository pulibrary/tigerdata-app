# frozen_string_literal: true

def reset_mediaflux_root
  # Clean out the namespace before running tests to avoid collisions
  user = User.new
  destroy_root_namespace(user)

  # then create it and the project root collection and namespace so it exists for any tests
  create_test_root_namespace(user)
  ProjectMediaflux.create_root_tree(session_id: user.mediaflux_session)
end

def destroy_root_namespace(user)
  destroy_request = Mediaflux::NamespaceDestroyRequest.new(
    session_token: user.mediaflux_session,
    namespace: Rails.configuration.mediaflux[:api_root_to_clean]
  )
  destroy_request.destroy
  if destroy_request.error?
    puts "Error destroying the mediaflux root namespace #{destroy_request.response_error}" # allow the message to show in CI output
  end
rescue => ex
  if ex.message.include?("does not exist")
    # no biggie
  else
    raise
  end
end

def create_test_root_namespace(user)
  create_request = Mediaflux::NamespaceCreateRequest.new(
    session_token: user.mediaflux_session,
    namespace: Rails.configuration.mediaflux[:api_root_to_clean]
  )
  create_request.resolve
  if create_request.error?
    puts "Error creating #{Rails.configuration.mediaflux[:api_root_to_clean]}: #{create_request.response_error}" # allow the message to show in CI output
  end
end

# Allow real connections to the Mediaflux server when a test is configured with
# connect_to_mediaflux: true
RSpec.configure do |config|
  config.before(:each) do |ex|
    if ex.metadata[:connect_to_mediaflux]
      # Ensure the latest mediaflux schema has been loaded before running the tests
      # Since we are testing against the Ansbile-provisioned Mediaflux server, we do not need to change the host api here

      require "rake"
      Rails.application.load_tasks

      # change the api host for all tests to '0.0.0.0' if MFLUX_LOCAL is set
      if ENV["MFLUX_LOCAL"]
        @original_api_host = Rails.configuration.mediaflux["api_host"]
        Rails.configuration.mediaflux["api_host"] = "0.0.0.0"
      end

      Rake::Task["schema:create"].invoke
      reset_mediaflux_root
    end
  rescue StandardError => namespace_error
    message = "Bypassing pre-test cleanup error, #{namespace_error.message}"
    puts message # allow the message to show in CI output
    Rails.logger.error(message)
  end

  config.after(:each) do |ex|
    if ex.metadata[:connect_to_mediaflux]
      if ENV["MFLUX_LOCAL"]
        Rails.configuration.mediaflux["api_host"] = @original_api_host
      end
    end
  end

  config.after(:suite) do |_ex|
    # Clean up the root namespace after all tests have run
    reset_mediaflux_root
  end
end
