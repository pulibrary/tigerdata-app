# frozen_string_literal: true
require "rails_helper"

describe MediafluxScriptFactory do
  subject(:mediaflux_service) { described_class.new(project_id) }
  let(:project) { FactoryBot.create(:approved_project) }
  let(:project_id) { project.id }

  describe "#department_fields" do
    let(:output) { mediaflux_service.department_fields }

    it "concatenates the names of all department fields" do
      expect(output).not_to be nil
      expect(output).to include(":Department \"PRDS\"")
      expect(output).to include(":Department \"RDSS\"")
    end
  end

  describe "#created_on" do
    let(:output) { mediaflux_service.created_on }

    it "formats the date into a valid DateTime stamp" do
      expect(output).not_to be nil
      parsed = DateTime.parse(output)
      expect(parsed).to be_a(DateTime)
    end
  end

  describe "#requested_by" do
    let(:output) { mediaflux_service.requested_by }

    it "accesses the user ID of the requesting user" do
      expect(output).not_to be nil
      user = User.find_by(uid: output)
      expect(user).not_to be nil
      expect(user.uid).to eq(output)
    end
  end

  describe "#requested_date" do
    let(:output) { mediaflux_service.requested_date }

    it "formats the date into a valid DateTime stamp" do
      expect(output).not_to be nil
      parsed = DateTime.parse(output)
      expect(parsed).to be_a(DateTime)
    end
  end

  describe "#build_create_script" do
    let(:output) { mediaflux_service.build_create_script }

    it "generates the Mediaflux API script for creating a project" do
      expect(output).to be_a(String)
      expect(output).to include(":pid path=#{project.project_directory_parent_path}")
      expect(output).to include(":namespace #{project.project_directory_parent_path}")
      expect(output).to include(":name #{project.project_directory_parent_path}")
      # Metadata
      expect(output).to include(":ProjectDirectory \"#{project.project_directory}\"")
      expect(output).to include(":Title \"#{project.metadata[:title]}\"")
      expect(output).to include(":Description \"#{project.metadata[:description]}\"")
      expect(output).to include(":Status \"#{project.metadata[:status]}\"")
      expect(output).to include(":DataSponsor \"#{project.metadata[:data_sponsor]}\"")
      expect(output).to include(":DataManager \"#{project.metadata[:data_manager]}\"")
      expect(output).to include(":CreatedBy \"#{project.metadata[:created_by]}\"")
      expect(output).to include(":ProjectID \"#{project.metadata[:project_id]}\"")
      expect(output).to include(":StorageCapacity < :Size \"#{project.metadata[:storage_capacity][:size][:requested]}>\"")
      expect(output).to include(":Unit #{project.metadata[:storage_capacity][:unit][:requested]}\"")
      expect(output).to include(":StoragePerformance \"#{project.metadata[:storage_performance_expectations][:requested]}\"")
      expect(output).to include(":ProjectPurpose \"#{project.metadata[:project_purpose]}\"")
      expect(output).to include(":SchemaVersion \"#{project.metadata[:schema_version]}\"")
    end
  end
end
