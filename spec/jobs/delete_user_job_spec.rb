# frozen_string_literal: true
require "rails_helper"

RSpec.describe DeleteUserJob, stub_mediaflux: true do
  let(:user) { FactoryBot.create(:user) }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123") }
  let(:metadata) do
    {
      data_sponsor: sponsor_user.uid,
      data_manager: sponsor_user.uid,
      project_directory: "project-123",
      title: "project 123",
      departments: ["RDSS"],
      description: "hello world",
      status: ::Project::PENDING_STATUS
    }
  end

  let(:project_in_mediaflux) { FactoryBot.create(:project, mediaflux_id: 8888, metadata: metadata) }

  before do
    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
      .with(body: /<service name=\"asset.query\" session=\"test-session-token\">/)
      .to_return(status: 200, body: fixture_file("files/query_response.xml"))

    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
      .with(body: /<service name=\"asset.query.iterate\" session=\"test-session-token\">/)
      .to_return(status: 200, body: fixture_file("files/iterator_response_get_values.xml"))

    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
      .with(body: /<service name=\"asset.query.iterator.destroy\" session=\"test-session-token\">/)
      .to_return(status: 200, body: "")
  end

  describe "#perform_now" do
    it "deletes the user job that requested file inventory" do
      # Request inventory
      job = ListProjectContentsJob.perform_now(user_id: user.id, project_id: project_in_mediaflux.id)

      # Delete the inventory request record after a week
      uid = user.id.to_s
      described_class.perform_now(user_id: uid, job_id: job.id)
      expect(user.user_jobs.where("id=#{job.id}").empty?).to be_truthy
    end
  end
end
