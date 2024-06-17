# frozen_string_literal: true
require "rails_helper"

describe UserRequest, type: :model do
  subject(:user_request) { described_class.create(**args) }

  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project) }
  # This uses the base class for all ActiveJobs within the application. Hence, any job should be supported.
  let(:job) { ListProjectContentsJob.new }

  describe "#user_id" do
    let(:args) do
      {
        user: user
      }
    end

    it "accesses and mutates the associations with user models" do
      expect(user_request.user).to be(user)
    end
  end

  describe "#project_id" do
    let(:args) do
      {
        project: project
      }
    end

    it "accesses and mutates the associations with project models" do
      expect(user_request.project).to be(project)
    end
  end

  describe "#job_id" do
    let(:args) do
      {
        job_id: job.job_id
      }
    end

    it "accesses and mutates the associations with ActiveJob instances" do
      expect(user_request.job_id).to eq(job.job_id)
    end
  end
end
