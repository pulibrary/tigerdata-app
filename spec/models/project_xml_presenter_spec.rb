# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectXmlPresenter, type: :model, connect_to_mediaflux: false do
  subject(:presenter) { described_class.new(project) }

  let(:data_sponsor) { FactoryBot.create(:project_sponsor, uid: "abc123") }
  let(:data_manager) { FactoryBot.create(:data_manager, uid: "bcd234") }
  let(:read_only) { FactoryBot.create :user }
  let(:read_write) { FactoryBot.create :user }
  let(:department) { "77777" }

  let(:metadata_model) do
    hash = {
      data_sponsor: data_sponsor.uid,
      data_manager: data_manager.uid,
      project_directory: "/tigerdata/abcd1/test-project-2",
      title: "project 123",
      departments: [department], # RDSS test code in fixture data
      description: "hello world",
      data_user_read_only: [read_only.uid],
      data_user_read_write: [read_write.uid],
      status: ::Project::PENDING_STATUS,
      created_on: Time.current.in_time_zone("America/New_York").iso8601,
      created_by: FactoryBot.create(:user).uid,
      project_id: "10.34770/az09-0004"
    }
    ProjectMetadata.new_from_hash(hash)
  end

  let(:project) { FactoryBot.create(:project_with_doi, data_sponsor: data_sponsor.uid, data_manager: data_manager.uid, metadata_model: metadata_model) }

  let(:schema_file_path) { Rails.root.join("lib", "assets", "tigerdata_metadata", "v0.8", "TigerData_StandardMetadataSchema_v0.8.xsd") }
  let(:schema_file) { File.read(schema_file_path) }
  let(:schema) { Nokogiri::XML::Schema(schema_file) }

  describe "#document" do
    let(:document) { presenter.document }
    let(:root) { document.root }

    it "generates a XML Document" do
      expect(document).to be_a(Nokogiri::XML::Document)
    end

    it "ensures that the root node is a <resource> element with the required attributes" do
      expect(root).to be_a(Nokogiri::XML::Element)
      expect(root.name).to eq("resource")
      expect(root["resourceClass"]).to eq("Project")
      expect(root["resourceID"]).to eq(project.metadata_model.project_id)
      expect(root["resourceIDType"]).to eq("DOI")
    end

    describe "<projectID>" do
      let(:node) { root.at_xpath("projectID") }

      it "builds a <projectID> element containing the ID of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("projectID")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
        expect(node.content).to eq(project.metadata_model.project_id)
      end
    end

    describe "<dataSponsor>" do
      let(:node) { root.at_xpath("dataSponsor") }

      it "builds a <dataSponsor> element containing the data sponsor of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("dataSponsor")
        expect(node["userID"]).to eq(project.metadata_model.data_sponsor)
        expect(node["discoverable"]).to eq("true")
        expect(node["inherited"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
      end
    end

    describe "<dataManager>" do
      let(:node) { root.at_xpath("dataManager") }

      it "builds a <dataManager> element containing the data manager of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("dataManager")
        expect(node["userID"]).to eq(project.metadata_model.data_manager)
        expect(node["discoverable"]).to eq("true")
        expect(node["inherited"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
      end
    end

    describe "<departments>" do
      let(:node) { root.at_xpath("departments") }

      it "builds a <departments> element containing the departments of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("departments")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
        expect(node.children.length).to eq(presenter.departments.length)
      end

      describe "<department>" do
        let(:node) { root.at_xpath("departments/department") }

        it "builds a <department> element for each department associated with the project" do
          expect(node).to be_a(Nokogiri::XML::Element)
          expect(node.name).to eq("department")
          expect(node["inherited"]).to eq("true")
          expect(node["departmentCode"]).to eq(presenter.departments.first)
          expect(node.content).to eq("0#{department}")
        end
      end
    end

    describe "<projectDirectory>" do
      let(:node) { root.at_xpath("projectDirectory") }

      it "builds a <projectDirectory> element containing the project directory structure information of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("projectDirectory")
        expect(node["approved"]).to eq("false")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("false")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
        expect(node.children.length).to eq(presenter.project_directory.length)
      end

      describe "<projectDirectoryPath>" do
        let(:node) { root.at_xpath("projectDirectory/projectDirectoryPath") }

        it "builds a <projectDirectoryPath> element containing project directory information for a file-system node" do
          expect(node).to be_a(Nokogiri::XML::Element)
          expect(node.name).to eq("projectDirectoryPath")
          expect(node["protocol"]).to eq("NFS")
          expect(node.content).to eq(presenter.project_directory.first)
        end
      end
    end

    describe "<title>" do
      let(:node) { root.at_xpath("title") }

      it "builds a <title> element containing the title of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("title")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
        expect(node.content).to eq(project.metadata_model.title)
      end
    end

    describe "<description>" do
      let(:node) { root.at_xpath("description") }

      it "builds a <description> element containing the description of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("description")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
        expect(node.content).to eq(project.metadata_model.description)
      end
    end

    describe "<projectPurpose>" do
      let(:node) { root.at_xpath("projectPurpose") }

      it "builds a <projectPurpose> element containing the stated purpose for the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("projectPurpose")
        expect(node["inherited"]).to eq("true")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
        expect(node.content).to eq(project.metadata_model.project_purpose)
      end
    end

    describe "<storageCapacity>" do
      let(:node) { root.at_xpath("storageCapacity") }

      it "builds a <storageCapacity> element containing the storage capacity information for the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("storageCapacity")
        expect(node["approved"]).to eq("false")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("false")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
      end
    end

    describe "<storagePerformance>" do
      let(:node) { root.at_xpath("storagePerformance") }

      it "builds a <storagePerformance> element containing the storage performance information for the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("storagePerformance")
        expect(node["approved"]).to eq("false")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("false")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
      end

      describe "<requestedValue>" do
        let(:node) { root.at_xpath("storagePerformance/requestedValue") }

        it "builds a <requestedValue> element containing the storage request information for the project" do
          expect(node).to be_a(Nokogiri::XML::Element)
          expect(node.name).to eq("requestedValue")
          expect(node.content).to eq(presenter.requested_storage)
        end
      end
    end

    describe "<projectProvenance>" do
      let(:node) { root.at_xpath("projectProvenance") }

      describe "<submission>" do
        let(:node) { root.at_xpath("projectProvenance/submission") }

        it "builds a <submission> element tracking the latest activity for the project" do
          expect(node).to be_a(Nokogiri::XML::Element)
          expect(node.name).to eq("submission")
        end
      end
    end

    describe "XSD schema validation" do
      let(:validation_errors) { schema.validate(document) }

      it "validates against the XSD schema document" do
        expect(validation_errors).to be_empty
      end
    end
  end
end
