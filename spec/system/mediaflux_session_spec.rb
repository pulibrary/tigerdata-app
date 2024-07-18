# frozen_string_literal: true

require "rails_helper"

# Makes sure the Application Controller handles Mediaflux::SessionExpired in a test from the user's perspective
#
RSpec.describe "Mediaflux Sessions", type: :system do
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123") }
  let(:project) { FactoryBot.create(:project, mediaflux_id: "abc123") }

  before do
    sign_in sponsor_user
  end

  it "reconnects to mediaflux after the session ends", connect_to_mediaflux: true do
    original_session = sponsor_user.mediaflux_session

    # logout the session so we get an error and need to reset the session
    Mediaflux::LogoutRequest.new(session_token: original_session).resolve

    expect { visit project_contents_path(project) }.not_to raise_error
    expect(page).to have_content("File Count\n0")

    # a new session got automatically connected for the user in the application controller
    expect(sponsor_user.mediaflux_session).not_to eq(original_session)
  end
end
