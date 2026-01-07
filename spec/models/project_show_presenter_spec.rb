# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectShowPresenter, type: :model, connect_to_mediaflux: false do
  let!(:current_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:request) do
    FactoryBot.create :request_project, data_manager: current_user.uid, data_sponsor: current_user.uid, departments: [{ "code" => "77777", "name" => "RDSS-Research Data and Scholarship Services" }]
  end
  let(:project) { request.approve(current_user) }
  subject(:presenter) { ProjectShowPresenter.new(project, current_user) }

  describe "#description" do
    it "delegates to project metdata_model" do
      expect(presenter.description).to eq(project.metadata_model.description)
    end
  end

  describe "#id" do
    it "delegates to project" do
      expect(presenter.id).to eq(project.id)
    end
  end

  describe "#in_mediaflux?" do
    it "delegates to project" do
      expect(presenter.in_mediaflux?).to eq(project.in_mediaflux?)
    end
  end

  describe "#mediaflux_id" do
    it "delegates to project" do
      expect(presenter.mediaflux_id).to eq(project.mediaflux_id)
    end
  end

  describe "#project_directory" do
    it "hides the root project" do
      expect(presenter.project_directory).to eq("/" + project.metadata_model.project_directory)
    end
  end

  describe "#project_id" do
    it "delegates to project metdata_model" do
      expect(presenter.project_id).to eq(project.metadata_model.project_id)
    end
  end

  describe "#project_purpose" do
    it "delegates to project metdata_model" do
      expect(presenter.project_purpose).to eq(project.metadata_model.project_purpose)
    end
  end

  describe "#status" do
    it "delegates to project" do
      expect(presenter.status).to eq(project.status)
    end
  end

  describe "#storage_capacity" do
    it "delegates to project metadata_model" do
      expect(presenter.storage_capacity).to eq(project.metadata_model.storage_capacity)
    end
  end

  describe "#storage_performance_expectations" do
    it "delegates to project metadata_model" do
      expect(presenter.storage_performance_expectations).to eq(project.metadata_model.storage_performance_expectations)
    end
  end

  describe "#title" do
    it "delegates to project" do
      expect(presenter.title).to eq(project.title)
    end
  end

  describe "#xml_document" do
    it "builds the XML document for the Project" do
      expect(presenter.xml_document).to be_a(Nokogiri::XML::Document)
    end
  end

  describe "#to_xml" do
    it "generates the string-serialized XML for the Project XML Document" do
      expect(presenter.to_xml).to be_a(String)
    end
  end

  describe "#department_codes" do
    before do
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
    end
    it "delegates to project metadata_model" do
      expect(presenter.department_codes.keys).to eq(project.metadata_model.departments)
    end
  end

  describe "#submission_provenance" do
    it "returns the hash containing the project submission and approval provenance" do
      expect(presenter.submission_provenance).to be_a(Hash)
      expect(presenter.submission_provenance).to eq(project.metadata_json["submission"])
    end
  end

  describe "#requested_by_uid" do
    it "returns the uid" do
      expect(presenter.requested_by_uid).to be_a(String)
      expect(presenter.requested_by_uid).to eq(project.metadata_json["submission"]["requested_by"])
    end

    context "when requested by is blank" do
      before do
        project.metadata_json["submission"]["requested_by"] = nil
      end

      it "returns an empty string" do
        expect(presenter.requested_by_uid).to be_a(String)
        expect(presenter.requested_by_uid).to eq("")
      end
    end
  end

  describe "#requested_by_display_name" do
    it "returns the display name " do
      expect(presenter.requested_by_display_name).to be_a(String)
      expect(presenter.requested_by_display_name).to eq(current_user.display_name_only_safe)
    end

    context "when requested by is blank" do
      before do
        project.metadata_json["submission"]["requested_by"] = nil
      end

      it "returns an empty string" do
        expect(presenter.requested_by_display_name).to be_a(String)
        expect(presenter.requested_by_display_name).to eq("NA")
      end
    end
  end

  describe "#requested_on" do
    it "generates the string-serialized XML for the Project XML Document" do
      expect(presenter.requested_on).to be_a(Hash)
    end
  end

  describe "#approved_by_uid" do
    it "returns the aprrover uid" do
      expect(presenter.approved_by_uid).to be_a(String)
      expect(presenter.approved_by_uid).to eq(project.metadata_json["submission"]["approved_by"])
    end

    context "when approved by is blank" do
      before do
        project.metadata_json["submission"]["approved_by"] = nil
      end

      it "returns an empty string" do
        expect(presenter.approved_by_uid).to be_a(String)
        expect(presenter.approved_by_uid).to eq("")
      end
    end
  end

  describe "#approved_by_display_name" do
    it "returns the approver uid" do
      expect(presenter.approved_by_display_name).to be_a(String)
      expect(presenter.approved_by_display_name).to eq(current_user.display_name_only_safe)
    end

    context "when approved by is blank" do
      before do
        project.metadata_json["submission"]["approved_by"] = nil
      end

      it "returns an empty string" do
        expect(presenter.approved_by_display_name).to be_a(String)
        expect(presenter.approved_by_display_name).to eq("NA")
      end
    end
  end
  describe "#approved_on" do
    it "generates the string-serialized XML for the Project XML Document" do
      expect(presenter.approved_on).to be_a(Hash)
    end
  end
end
