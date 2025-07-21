# frozen_string_literal: true
require "rails_helper"

RSpec.describe ActivateProjectJob, connect_to_mediaflux: true, type: :job do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:project_in_mediaflux) { FactoryBot.create(:project_with_doi, status: Project::APPROVED_STATUS) }

  before do
    ProjectMediaflux.create!(user: user, project: project_in_mediaflux)
  end

  describe "#perform_now" do
    it "marks the state as active",
    :integration do
      expect(project_in_mediaflux.status).to eq(Project::APPROVED_STATUS)
      described_class.perform_now(user: user, project_id: project_in_mediaflux.id)
      expect(Project.find(project_in_mediaflux.id).status).to eq(Project::ACTIVE_STATUS)
    end
  end
end
