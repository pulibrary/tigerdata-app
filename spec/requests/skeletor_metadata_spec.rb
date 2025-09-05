# frozen_string_literal: true

require "rails_helper"

RSpec.describe "The Skeletor Metadata", connect_to_mediaflux: true, metadata: true do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:data_manager) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:project) { FactoryBot.create(:approved_project, data_manager: data_manager.uid) }

  context "retrieves xml for a project" do
    before do
      sign_in data_manager
    end

    it "provides the xml metadata for a project" do
      get project_show_mediaflux_url(project), params: { format: :xml }
      expect(response.content_type).to match "xml"
    end
  end
end
