# frozen_string_literal: true
require "rails_helper"

RSpec.describe ActivateProjectJob, type: :job do
  let(:user) { FactoryBot.create(:user) }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123") }
  let(:collection_id) { 1170 }
  let(:approved_project) { FactoryBot.create :project }
  let(:metadata) do
    {
      data_sponsor: sponsor_user.uid,
      data_manager: sponsor_user.uid,
      directory: "project-123",
      title: "project 123",
      departments: ["RDSS"],
      description: "hello world",
      status: ::Project::PENDING_STATUS
    }
  end
  let(:project_in_mediaflux) { FactoryBot.create(:project, mediaflux_id: 8888, metadata: metadata) }


  describe "#perform_now", connect_to_mediaflux: true do
    it "updates the UserJob#completed_at attribute" do
      job = described_class.perform_now(user:, project_id: project_in_mediaflux.id)
      user_job = UserJob.where(job_id: job.job_id).first
      expect(user_job.completed_at).to_not be nil
    end

  end
end
