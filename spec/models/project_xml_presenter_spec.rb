# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectXmlPresenter, type: :model, connect_to_mediaflux: false do
  let(:project) { FactoryBot.create :project_with_doi }
  subject(:presenter) { described_class.new(project) }

  let(:schema_file_path) { Rails.root.join("lib", "assets", "tigerdata_metadata", "v0.8", "TigerData_StandardMetadataSchema_v0.8.xsd") }
  let(:schema_file) { File.read(schema_file_path) }
  let(:schema) { Nokogiri::XML::Schema(schema_file) }

  it "can be instantiated" do
    expect(presenter).to be_instance_of(described_class)
  end

  context "rails XML payload" do
    it "has an xml payload" do
    end
  end

  describe "#document" do
    it "generates a XML Document" do
      expect(presenter.document).to be_a(Nokogiri::XML::Document)
    end

    it "ensures that the root node is a <resource> element with the required attributes" do
      expect(presenter.document.root).to be_a(Nokogiri::XML::Element)
      expect(presenter.document.root.name).to eq("resource")
      expect(presenter.document.root["resourceClass"]).to eq("Project")
      expect(presenter.document.root["resourceID"]).to eq(project.metadata_model.project_id)
      expect(presenter.document.root["resourceIDType"]).to eq("DOI")
    end

    describe "<projectID>" do
      let(:node) { presenter.document.root.at_xpath("projectID") }

      it "builds a <projectID> element containing the title of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("projectID")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
        expect(node.content).to eq(project.metadata_model.project_id)
      end
    end

    describe "<departments>" do
      let(:node) { presenter.document.root.at_xpath("departments") }

      it "builds a <departments> element containing the title of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("departments")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
      end
    end

    describe "<title>" do
      let(:node) { presenter.document.root.at_xpath("title") }

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
      let(:node) { presenter.document.root.at_xpath("description") }

      it "builds a <description> element containing the title of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("description")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
        expect(node.content).to eq(project.metadata_model.description)
      end
    end

    describe "<projectPurpose>" do
      let(:node) { presenter.document.root.at_xpath("projectPurpose") }

      it "builds a <projectPurpose> element containing the title of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("projectPurpose")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
        expect(node.content).to eq(project.metadata_model.project_purpose)
      end
    end

    describe "<storagePerformance>" do
      let(:node) { presenter.document.root.at_xpath("storagePerformance") }

      it "builds a <storagePerformance> element containing the title of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("storagePerformance")
        expect(node["approved"]).to eq("false")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("false")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
        expect(node.children.length).to eq(1)
      end

      describe "<requestedValue>" do
        let(:node) { presenter.document.root.at_xpath("storagePerformance/requestedValue") }

        it "builds a <requestedValue> element containing the title of the project" do
          expect(node).to be_a(Nokogiri::XML::Element)
          expect(node.name).to eq("requestedValue")
          expect(node.content).to eq(project.metadata_model.storage_performance_expectations[:requested])
        end
      end
    end

    xit "validates against the XSD schema document" do
      expect(schema.valid?(presenter.document)).to be true
    end
  end
end
