# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectMetadata, type: :model do
  let(:researcher_user) { FactoryBot.create(:user, uid: "hc1234") }
  let(:project) { Project.new }
  let(:project_metadata) { described_class.new }
  let(:data_security_level) { nil } # no default is set for security level
  let(:hash) do
    {
      data_sponsor: "abc",
      data_manager: "def",
      departments: "dep",
      project_directory: " dir ",
      title: "title abc",
      description: "description 123",
      status: "approved",
      data_security_level: data_security_level
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
      expect(project_metadata.status).to eq("approved")
      expect(project_metadata.data_security_level).to be_nil
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

    context "when security level is provided" do
      let(:data_security_level) { 3 }

      it "sets the data security level" do
        project_metadata.initialize_from_hash(hash)
        expect(project_metadata.data_security_level).to eq(3)
      end
    end
  end

  describe "#safe_directory" do
    it "handles nil values" do
      expect(described_class.safe_directory(nil)).to eq ""
    end

    it "honors dashes and underscores" do
      expect(described_class.safe_directory("abc_123")).to eq "abc_123"
      expect(described_class.safe_directory("abc-456")).to eq "abc-456"
    end

    it "replaces unexpected characters with dashes" do
      expect(described_class.safe_directory("hello#world{x}")).to eq "hello-world-x-"
    end
  end
end
