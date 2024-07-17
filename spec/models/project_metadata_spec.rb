# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectMetadata, type: :model do
  let(:current_user) { FactoryBot.create(:user, uid: "hc1234") }
  let(:project) { Project.new }
  let(:project_metadata) { described_class.new }
  let(:hash) do
    {
      data_sponsor: "abc",
      data_manager: "def",
      departments: "dep",
      project_directory: "dir",
      title: "title abc",
      description: "description 123",
      status: "pending"
    }.with_indifferent_access
  end

  let(:default_storage_capacity) do
    { requested: 500, approved: nil }.with_indifferent_access
  end

  let(:default_storage_performance_expectations) do
    { requested: "Standard", approved: nil }.with_indifferent_access
  end

  let(:default_project_purpose) { "Research" }

  describe "#initialize_from_hash" do
    it "parses basic metadata" do
      project_metadata.initialize_from_hash(hash)
      expect(project_metadata.data_sponsor).to eq("abc")
      expect(project_metadata.data_manager).to eq("def")
      expect(project_metadata.departments).to eq("dep")
      expect(project_metadata.project_directory).to eq("dir")
      expect(project_metadata.title).to eq("title abc")
      expect(project_metadata.description).to eq("description 123")
      expect(project_metadata.status).to eq("pending")
    end

    it "sets the default values when not given" do
      project_metadata.initialize_from_hash(hash)
      expect(project_metadata.storage_capacity[:size].with_indifferent_access).to eq default_storage_capacity
      expect(project_metadata.storage_performance_expectations.with_indifferent_access).to eq default_storage_performance_expectations
      expect(project_metadata.project_purpose).to eq default_project_purpose
    end

    it "overwrites default values when given" do
      hash[:project_purpose] = "Not research"
      project_metadata.initialize_from_hash(hash)
      expect(project_metadata.project_purpose).to eq "Not research"
    end
  end

  describe "#initialize_from_params" do
    it "uses the provided timestamps (when available)" do
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.created_by).to be_blank
      expect(project_metadata.created_on).to be_blank
      expect(project_metadata.updated_on).to be_blank
      expect(project_metadata.updated_by).to be_blank

      hash[:created_on] = Time.current.in_time_zone("America/New_York").iso8601
      hash[:created_by] = "user1"
      hash[:updated_on] = Time.current.in_time_zone("America/New_York").iso8601
      hash[:updated_by] = "user2"
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.created_by).to_not be_blank
      expect(project_metadata.created_on).to_not be_blank
      expect(project_metadata.updated_on).to_not be_blank
      expect(project_metadata.updated_by).to_not be_blank
    end

    it "parses the read only users" do
      hash[:ro_user_1] = "abc"
      hash[:ro_user_counter] = "1"
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.ro_users).to eq(["abc"])
    end

    it "parses empty read only users" do
      hash[:ro_user_counter] = "0"
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.ro_users).to eq([])
    end

    it "parses the read/write users" do
      hash[:rw_user_1] = "rwx"
      hash[:rw_user_counter] = "1"
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.rw_users).to eq(["rwx"])
    end

    it "parses empty read/write users" do
      hash[:rw_user_counter] = "0"
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.rw_users).to eq([])
    end
  end

  describe "#update_with_params" do
    it "sets the values in the params" do
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.title).to eq("title abc")

      # it blanks the title
      hash["title"] = nil
      project_metadata.update_with_params(hash, current_user)
      expect(project_metadata.title).to be nil

      # changes the title when one is given
      hash["title"] = "title abc again"
      project_metadata.update_with_params(hash, current_user)
      expect(project_metadata.title).to eq("title abc again")
    end
  end
end
