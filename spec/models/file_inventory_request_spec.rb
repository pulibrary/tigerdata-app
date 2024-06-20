# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileInventoryRequest, type: :model do
  let(:file_inventory_request) do
    described_class.create(user_id: user.id, project_id: project.id, job_id: job.job_id, completion_time: completion_time, state: state, request_details: request_details)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project) }
  let(:job) { FileInventoryJob.new }
  let(:completion_time) { Time.current.in_time_zone("America/New_York").iso8601 }
  let(:state) { UserRequest::PENDING }
  let(:request_details) { { output_file: "filename" } }

  describe "#type" do
    it "has a type representing the class name" do
      expect(file_inventory_request.type).to eq("FileInventoryRequest")
    end
  end
  describe "#output_file" do
    it "accesses the output file" do
      expect(file_inventory_request.output_file).to eq("filename")
    end
end
end
