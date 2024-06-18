# frozen_string_literal: true
require "rails_helper"

describe UserRequest, type: :model do
  let(:user_request) { described_class.create(user_id: user.id, project_id: project.id, job_id: job.job_id) }

  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project) }
  # This uses the base class for all ActiveJobs within the application. Hence, any job should be supported.
  let(:job) { ListProjectContentsJob.new }

  describe "#user_id" do
    it "has a user id" do
      expect(user_request.user.id).to be(user.id)
    end
  end

  describe "#project_id" do
    it "has a project id" do
      expect(user_request.project.id).to be(project.id)
    end
  end

  describe "#job_id" do
    it "has a job id" do
      expect(user_request.job_id).to eq(job.job_id)
    end
  end
end
