# frozen_string_literal: true
require "rails_helper"

RSpec.describe MediafluxInfoController, connect_to_mediaflux: true do
  let(:user) { FactoryBot.create :user, mediaflux_session: SystemUser.mediaflux_session }
  let(:docker_response) { "{\"vendor\":\"Arcitecta Pty. Ltd.\",\"version\":\"4.16.088\"}" }

  before do
    sign_in user
  end

  it "gets the mediaflux information" do
    expect { get :index, format: "json" }.not_to raise_error
    expect(response.body).to eq(docker_response)
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
