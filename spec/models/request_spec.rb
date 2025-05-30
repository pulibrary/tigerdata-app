# frozen_string_literal: true
require "rails_helper"

RSpec.describe Request, type: :model do
  let(:request) do
    described_class.create(request_type: "new_project_request", request_title: "Request for Example Project", project_title: "Example Project",
                           data_sponsor: "sponsor", data_manager: "manager", departments: "dept", description: "description", parent_folder: "folder",
                           project_folder: "project", project_id: "doi", quota: "500 GB", requested_by: "uid", user_roles: [{ uid: "abc123", name: "Abe Cat" }, { uid: "ddd", name: "Dandy Dog" }])
  end

  describe "#request_type" do
    subject(:request_type) { request.request_type }
    it { should eq("new_project_request") }
  end

  describe "#request_title" do
    subject(:request_title) { request.request_title }
    it { should eq("Request for Example Project") }
  end

  describe "#project_title" do
    subject(:project_title) { request.project_title }
    it { should eq("Example Project") }
  end

  describe "#data_sponsor" do
    subject(:data_manager) { request.data_sponsor }
    it { should eq("sponsor") }
  end

  describe "#data_manager" do
    subject(:data_manager) { request.data_manager }
    it { should eq("manager") }
  end

  describe "#departments" do
    subject(:departments) { request.departments }
    it { should eq("dept") }
  end

  describe "#description" do
    subject(:description) { request.description }
    it { should eq("description") }
  end

  describe "#parent_folder" do
    subject(:parent_folder) { request.parent_folder }
    it { should eq("folder") }
  end

  describe "#project_folder" do
    subject(:project_folder) { request.project_folder }
    it { should eq("project") }
  end

  describe "#project_id" do
    subject(:project_id) { request.project_id }
    it { should eq("doi") }
  end

  describe "#quota" do
    subject(:quota) { request.quota }
    it { should eq("500 GB") }
  end

  describe "#requested_by" do
    subject(:requested_by) { request.requested_by }
    it { should eq("uid") }
  end

  describe "#user_roles" do
    subject(:user_roles) { request.user_roles }
    it { should eq([{ "uid" => "abc123", "name" => "Abe Cat" }, { "uid" => "ddd", "name" => "Dandy Dog" }]) }
  end

  describe "#valid_title?" do
    it "requires a title" do
      request = Request.new(project_title: "")
      expect(request.valid_title?).to be_falsey
      request.project_title = "abc"
      expect(request.valid_title?).to be_truthy
    end
  end

  describe "#valid_data_sponsor?" do
    it "requires a data_sponsor" do
      request = Request.new(data_sponsor: "")
      expect(request.valid_data_sponsor?).to be_falsey
      request.data_sponsor = "abc"
      expect(request.valid_data_sponsor?).to be_truthy
    end
  end

  describe "#valid_data_manager?" do
    it "requires a data_manager" do
      request = Request.new(data_manager: "")
      expect(request.valid_data_manager?).to be_falsey
      request.data_manager = "abc"
      expect(request.valid_data_manager?).to be_truthy
    end
  end

  describe "#valid_departments?" do
    it "requires departments" do
      request = Request.new(departments: "")
      expect(request.valid_departments?).to be_falsey
      request.departments = "abc"
      expect(request.valid_departments?).to be_truthy
    end
  end

  describe "#valid_description?" do
    it "requires a description" do
      request = Request.new(description: "")
      expect(request.valid_description?).to be_falsey
      request.description = "abc"
      expect(request.valid_description?).to be_truthy
    end
  end

  describe "#valid_parent_folder?" do
    it "requires a parent_folder" do
      request = Request.new(parent_folder: "")
      expect(request.valid_parent_folder?).to be_falsey
      request.parent_folder = "abc"
      expect(request.valid_parent_folder?).to be_truthy
    end
  end

  describe "#valid_project_folder?" do
    it "requires a project_folder" do
      request = Request.new(project_folder: "")
      expect(request.valid_project_folder?).to be_falsey
      request.project_folder = "abc"
      expect(request.valid_project_folder?).to be_truthy
    end
  end

  describe "#valid_quota?" do
    it "requires a quota to be positive" do
      request = Request.new(quota: "")
      expect(request.valid_quota?).to be_falsey
      request.quota = "500 GB"
      expect(request.valid_quota?).to be_truthy
      request.quota = "2 TB"
      expect(request.valid_quota?).to be_truthy
      request.quota = "10 TB"
      expect(request.valid_quota?).to be_truthy
      request.quota = "25 TB"
      expect(request.valid_quota?).to be_truthy
      request.quota = "23 TB"
      expect(request.valid_quota?).to be_falsey
      request.quota = "custom"
      expect(request.valid_quota?).to be_falsey
      request.storage_size = 23
      request.storage_unit = "TB"
      expect(request.valid_quota?).to be_truthy
    end
  end

  describe "#valid_requested_by?" do
    it "requires a requested_by" do
      request = Request.new(requested_by: "")
      expect(request.valid_requested_by?).to be_falsey
      request.requested_by = "abc"
      expect(request.valid_requested_by?).to be_truthy
    end
  end

  describe "#valid_to_submit?" do
    it "requires all the validations to be true" do
      request = Request.new
      expect(request.valid_to_submit?).to be_falsey
      request.project_title = "abc"
      expect(request.valid_to_submit?).to be_falsey
      request.data_sponsor = "abc"
      expect(request.valid_to_submit?).to be_falsey
      request.data_manager = "abc"
      expect(request.valid_to_submit?).to be_falsey
      request.parent_folder = "abc"
      expect(request.valid_to_submit?).to be_falsey
      request.departments = "abc"
      expect(request.valid_to_submit?).to be_falsey
      request.parent_folder = "abc"
      expect(request.valid_to_submit?).to be_falsey
      request.project_folder = "abc"
      expect(request.valid_to_submit?).to be_falsey
      request.quota = 500
      expect(request.valid_to_submit?).to be_falsey
      request.requested_by = "abc"
      expect(request.valid_requested_by?).to be_truthy
    end
  end
end
