# frozen_string_literal: true
require "rails_helper"

RSpec.describe Request, type: :model do
  let(:request) do
    described_class.create(request_type: "new_project_request", request_title: "Request for Example Project", project_title: "Example Project",
                           data_sponsor: "sponsor", data_manager: "manager", departments: "dept", description: "description", parent_folder: "folder",
                           project_folder: "project", project_id: "doi", quota: 500, requested_by: "uid")
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
    it { should eq(500) }
  end

  describe "#requested_by" do
    subject(:requested_by) { request.requested_by }
    it { should eq("uid") }
  end
end
