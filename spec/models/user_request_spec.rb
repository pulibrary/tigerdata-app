# frozen_string_literal: true
require "rails_helper"
require "json"

describe InventoryRequest, type: :model do
  let(:inventory_request) { described_class.create(user_id: user.id, project_id: project.id, job_id: job.job_id, completion_time: completion_time, state: state, request_details: request_details) }

  let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:project) { FactoryBot.create(:project) }
  let(:job) { FileInventoryJob.new }
  let(:completion_time) { Time.current.in_time_zone("America/New_York").iso8601 }
  let(:state) { InventoryRequest::PENDING }
  let(:request_details) { { temp_key: "temp_val" } }

  describe "#user_id" do
    it "has a user id" do
      expect(inventory_request.user.id).to be(user.id)
    end
  end

  describe "#project_id" do
    it "has a project id" do
      expect(inventory_request.project.id).to be(project.id)
    end
  end

  describe "#job_id" do
    it "has a job id" do
      expect(inventory_request.job_id).to eq(job.job_id)
    end
  end

  describe "#created_at" do
    it "has a creation time" do
      expect(inventory_request.created_at).to be_instance_of(ActiveSupport::TimeWithZone)
    end
  end

  describe "#completion_time" do
    it "has a completion time" do
      expect(inventory_request.completion_time).to eq(completion_time)
    end
  end

  describe "#state" do
    it "has a state" do
      expect(inventory_request.state).to eq(state)
    end

    it "can be pending" do
      inventory_request.state = InventoryRequest::PENDING
      inventory_request.save
      expect(inventory_request.state).to eq(InventoryRequest::PENDING)
    end

    it "can be completed" do
      inventory_request.state = InventoryRequest::COMPLETED
      inventory_request.save
      expect(inventory_request.state).to eq(InventoryRequest::COMPLETED)
    end

    it "can be stale" do
      inventory_request.state = InventoryRequest::STALE
      inventory_request.save
      expect(inventory_request.state).to eq(InventoryRequest::STALE)
    end

    it "can be failed" do
      inventory_request.state = InventoryRequest::FAILED
      expect(inventory_request.save).to be(true)
      expect(inventory_request.state).to eq(InventoryRequest::FAILED)
    end

    it "has an error if set to a non-standard value" do
      inventory_request.state = "foobar"
      expect(inventory_request.save).to be(false)
      expect(inventory_request.errors[:state]).to include("is not included in the list")
    end
  end

  describe "#request_details" do
    it "has request details in json" do
      expect(inventory_request.request_details["temp_key"]).to eq("temp_val")
    end
  end

  describe "#complete?" do
    it "returns true if the current state is completed" do
      expect(inventory_request.complete?).to be_falsey
      inventory_request.update(state: InventoryRequest::COMPLETED)
      expect(inventory_request.complete?).to be_truthy
    end
  end
end
