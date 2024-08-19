# frozen_string_literal: true
require "rails_helper"

RSpec.describe MediafluxInfoController do
  let(:user) { FactoryBot.create :user }
  before do
    sign_in user
  end

  it "gets the mediaflux information", connect_to_mediaflux: true do
    expect { get :index, format: "json" }.not_to raise_error(Mediaflux::SessionExpired)
    expect(response.body).to eq("{\"vendor\":\"Arcitecta Pty. Ltd.\",\"version\":\"4.16.047\"}")
  end

  it "does not retry infinately", connect_to_mediaflux: true do
    original_pass = Rails.configuration.mediaflux["api_password"]
    original_session = user.mediaflux_session

    # logout the session so we get an error and need to reset the session
    Mediaflux::LogoutRequest.new(session_token: original_session).resolve

    Rails.configuration.mediaflux["api_password"] = "badpass"

    expect { get :index }.to raise_error(Mediaflux::SessionExpired)

    Rails.configuration.mediaflux["api_password"] = original_pass
  end
end
