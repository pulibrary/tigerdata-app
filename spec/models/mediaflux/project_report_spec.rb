# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ProjectReport, connect_to_mediaflux: true, type: :model do
  let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:approved_project) { FactoryBot.create(:approved_project) }

  describe "#result" do
    before do
      approved_project.approve!(current_user: user)
      Mediaflux::TestAssetCreateRequest.new(session_token: user.mediaflux_session, parent_id: approved_project.mediaflux_id).resolve
    end

    it "returns csv data with one row for our test project",
    :integration do
      report = described_class.new(session_token: user.mediaflux_session)
      mediaflux_projects = CSV.new(report.csv_data, headers: true).to_a

      # the mediaflux command gets ALL the project in mediaflux
      #  since we have development and test in our single mediaflux instance we have to filter
      test_project = mediaflux_projects.select { |project| project["asset"].to_i == approved_project.mediaflux_id }
      expect(test_project.count).to eq(1)
      expect(test_project.first["projectID"]).to eq(approved_project.metadata_model.project_id)
    end
  end
end
