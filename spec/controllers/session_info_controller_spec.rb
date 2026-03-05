# frozen_string_literal: true
require "rails_helper"

RSpec.describe SessionInfoController, connect_to_mediaflux: true do
  let(:user) { FactoryBot.create :user, mediaflux_session: SystemUser.mediaflux_session }
  let(:keys) { ["uuid", "name", "server_version", "tigerdata_config_version", "tigerdata_plugin_version"] }

  before do
    sign_in user
  end

  it "gets the mediaflux information" do
    expect { get :index, format: "json" }.not_to raise_error
    json = JSON.parse(response.body)
    # Check for the presence of the expected keys in the response
    # (but not their values since they change frequently)
    keys.each do |key|
      expect(json.key?(key)).to be true
    end
  end

  it "does not retry infinitely" do
    original_pass = Rails.configuration.mediaflux["api_password"]
    original_session = user.mediaflux_session

    # logout the session so we get an error and need to reset the session
    Mediaflux::LogoutRequest.new(session_token: original_session).resolve

    Rails.configuration.mediaflux["api_password"] = "badpass"

    expect { get :index }.to raise_error(Mediaflux::SessionError)

    Rails.configuration.mediaflux["api_password"] = original_pass
  end
end
