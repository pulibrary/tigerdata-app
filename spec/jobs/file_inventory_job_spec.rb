# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileInventoryJob, connect_to_mediaflux: true do
  let(:user) { FactoryBot.create(:user) }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123") }
  let(:project_in_mediaflux) { FactoryBot.create(:project_with_doi)}

  describe "#perform_now" do
    let(:file_inventory_job) { described_class.perform_now(user_id:, project_id:) }
    it "creates a file inventory request attached to the user and the project" do
      expect(FileInventoryRequest.count).to be 0
      FileInventoryJob.perform_now(user_id: user.id, project_id: project_in_mediaflux.id)
      expect(FileInventoryRequest.count).to be 1
      file_inventory_request = FileInventoryRequest.first 
      expect(file_inventory_request.state).to eq UserRequest::PENDING
    end
    it "updates the UserJob#completed_at attribute" do
      job = described_class.perform_now(user_id: user.id, project_id: project_in_mediaflux.id)
      user_job = UserJob.where(job_id: job.job_id).first
      expect(user_job.completed_at).to_not be nil
    end

    it "saves the output to a file" do
      job = described_class.perform_now(user_id: user.id, project_id: project_in_mediaflux.id)
      output_file = Pathname.new(Rails.configuration.mediaflux["shared_files_location"]).join("#{job.job_id}.csv").to_s
      expect(File.exist?(output_file)).to be true
    end

    context "when an invalid User ID is specified" do
      it "raises an error" do
        expect do
          described_class.perform_now(user_id: "invalid-id", project_id: project_in_mediaflux.id)
        end.to raise_error(ActiveRecord::RecordNotFound, /Couldn't find User/)
      end
    end
  end
end
