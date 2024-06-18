# frozen_string_literal: true
require "rails_helper"

RSpec.describe ActivateProjectRequest, type: :model do
  let(:activate_project_request) do
    described_class.create(user_id: user.id, project_id: project.id, job_id: job.job_id, completion_time: completion_time, state: state, request_details: request_details)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project) }
  let(:job) { ListProjectContentsJob.new }
  let(:completion_time) { Time.current.in_time_zone("America/New_York").iso8601 }
  let(:state) { UserRequest::PENDING }
  let(:request_details) { { temp_key: "temp_val" } }

  describe "#type" do
    it "has a type representing the class name" do
      expect(activate_project_request.type).to eq("ActivateProjectRequest")
    end
  end
end
