# frozen_string_literal: true
require "rails_helper"

RSpec.describe ListProjectContentsJob, stub_mediaflux: true do
  let(:user) { FactoryBot.create(:user) }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123") }
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

  before do
    stub_request(:post, "http://#{ENV['MEDIAFLUX_HOST']}:8888/__mflux_svc__")
      .with(body: /<service name=\"asset.query\" session=\"test-session-token\">/)
      .to_return(status: 200, body: fixture_file("files/query_response.xml"))

    stub_request(:post, "http://#{ENV['MEDIAFLUX_HOST']}:8888/__mflux_svc__")
      .with(body: /<service name=\"asset.query.iterate\" session=\"test-session-token\">/)
      .to_return(status: 200, body: fixture_file("files/iterator_response_get_values.xml"))

    stub_request(:post, "http://#{ENV['MEDIAFLUX_HOST']}:8888/__mflux_svc__")
      .with(body: /<service name=\"asset.query.iterator.destroy\" session=\"test-session-token\">/)
      .to_return(status: 200, body: "")
  end

  describe "#perform_now" do
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
