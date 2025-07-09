# frozen_string_literal: true
require "rake"
Rails.application.load_tasks

def reset_mediaflux_root
  # # Clean out the namespace before running tests to avoid collisions
  # user = SystemUser
  # destroy_root_namespace(user)

  # # then create it and the project root collection and namespace so it exists for any tests
  # create_test_root_namespace(user)
  # ProjectMediaflux.create_root_tree(session_id: user.mediaflux_session)

  # Clear the login cache
  Rails.cache.clear
end

# def destroy_root_namespace(user)
#   destroy_request = Mediaflux::NamespaceDestroyRequest.new(
#     session_token: user.mediaflux_session,
#     namespace: Rails.configuration.mediaflux[:api_root_to_clean]
#   )
#   destroy_request.destroy
#   if destroy_request.error?
#     puts "Error destroying the mediaflux root namespace #{destroy_request.response_error}" # allow the message to show in CI output
#   end
# rescue => ex
#   if ex.message.include?("does not exist")
#     # no biggie
#   else
#     raise
#   end
# end

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

# When connect_to_mediaflux is true reset the mediaflux server and make sure it is setup for the tests
RSpec.configure do |config|
  config.before(:each) do |_ex|
    reset_mediaflux_root
  rescue StandardError => namespace_error
    message = "Bypassing pre-test cleanup error, #{namespace_error.message}"
    puts message # allow the message to show in CI output
    Rails.logger.error(message)
  end

  # config.before(:suite) do |_ex|
  #   # Ensure the latest mediaflux schema has been loaded before running the tests
  #   Rake::Task["schema:create"].reenable
  #   Rake::Task["schema:create"].invoke
  # end

  config.after(:suite) do |_ex|
    reset_mediaflux_root
  end
end
