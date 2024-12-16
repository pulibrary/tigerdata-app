# frozen_string_literal: true

require "rails_helper"

# Makes sure the Application Controller handles Mediaflux::SessionExpired in a test from the user's perspective
#
RSpec.describe "Mediaflux Sessions", type: :system do
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123") }
  let(:project) { FactoryBot.create(:project, mediaflux_id: "abc123") }

  context "user is signed in" do
    let(:original_session) { SystemUser.mediaflux_session }
    let(:new_session) { SystemUser.mediaflux_session }
    let(:mediaflux_logon) { instance_double Mediaflux::LogonRequest, error?: false, session_token: new_session }

    before do
      sign_in sponsor_user
      allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).and_call_original
      allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).with(:mediaflux_session).and_return(original_session)
      allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).with(:active_web_user).and_return(true)
    end

    it "connects to mediaflux once", connect_to_mediaflux: true do
      visit root_path

      expect { visit project_path(project) }.not_to raise_error
      expect(page).to have_content("Total Files: 0")

      expect(sponsor_user.mediaflux_session).to eq(original_session)
    end
  end
end
