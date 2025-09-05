# frozen_string_literal: true

require "rails_helper"

RSpec.describe "The Skeletor Metadata", connect_to_mediaflux: true, metadata: true do
  context "retrieves xml for a project" do
    let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
    let(:project) { FactoryBot.create(:approved_project, sponsor_and_data_manager_user: sponsor_and_data_manager_user.uid) }

    before do
      project.approve!(current_user: sponsor_and_data_manager_user)
      sign_in sponsor_and_data_manager_user
    end

    # it "provides the xml metadata for a project" do
    # get project_show_mediaflux_url(project), params: { format: :xml }
    # byebug
    # end
  end
end
