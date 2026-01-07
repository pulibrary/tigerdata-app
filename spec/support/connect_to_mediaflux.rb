# frozen_string_literal: true
require "rake"
Rails.application.load_tasks

# When connect_to_mediaflux is true reset the mediaflux server and make sure it is setup for the tests
RSpec.configure do |config|
  config.before(:each) do |_ex|
    # Clear the login cache
    Rails.cache.clear
  rescue StandardError => namespace_error
    message = "Bypassing pre-test cleanup error, #{namespace_error.message}"
    puts message # allow the message to show in CI output
    Rails.logger.error(message)
  end

  config.after(:suite) do |_ex|
    Mediaflux::NamespaceDestroyRequest.new(session_token: SystemUser.mediaflux_session, namespace: "/princeton/tigerdataNS/rspecNS", ignore_missing: true).resolve
  end
end
