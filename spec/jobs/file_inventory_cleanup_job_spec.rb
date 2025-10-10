# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileInventoryCleanupJob, connect_to_mediaflux: true, type: :job, integration: true do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:project_in_mediaflux) do
    request = FactoryBot.create(:request_project)
    request.approve(sponsor_and_data_manager_user)
  end
  let(:eight_days_ago) { Time.current.in_time_zone("America/New_York") - 8.days }

  describe "#perform_now" do
    it "deletes any files older than 7 days" do
      req = FileInventoryJob.perform_now(user_id: user.id, project_id: project_in_mediaflux.id, mediaflux_session: user.mediaflux_session)
      req.completion_time = eight_days_ago
      req.save

      expect(File.exist?(req.output_file)).to be_truthy
      described_class.perform_now
      expect(File.exist?(req.output_file)).to be_falsey
    end

    it "marks the file inventory request stale" do
      req = FileInventoryJob.perform_now(user_id: user.id, project_id: project_in_mediaflux.id, mediaflux_session: user.mediaflux_session)
      req.completion_time = eight_days_ago
      req.save

      expect(req.state).to eq(UserRequest::COMPLETED)
      described_class.perform_now
      req.reload
      expect(req.state).to eq(UserRequest::STALE)
    end

    it "handles requests without an output file" do
      req = FileInventoryJob.perform_now(user_id: user.id, project_id: project_in_mediaflux.id, mediaflux_session: user.mediaflux_session)
      req.completion_time = eight_days_ago
      req.request_details = { error: "Mediaflux session expired", project_title: "Some Laboratory" }
      req.state = UserRequest::FAILED
      req.save

      described_class.perform_now
      req.reload
      expect(req.state).to eq(UserRequest::FAILED)
    end
  end
end
