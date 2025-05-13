# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectXmlPresenter, type: :model, connect_to_mediaflux: false do
  let(:project) { FactoryBot.create :project_with_doi }
  subject(:presenter) { described_class.new(project) }

  it "can be instantiated" do
    expect(presenter).to be_instance_of(described_class)
  end

  context "rails XML payload" do
    it "has an xml payload" do
    end
  end

  describe "#to_xml" do
    it "generates a XML Document" do
      expect(presenter.to_xml).to be_a(Nokogiri::XML::Document)
    end

    it "ensures that the root node is a <resource> element with the required attributes" do
      expect(presenter.to_xml.root).to be_a(Nokogiri::XML::Element)
      expect(presenter.to_xml.root.name).to eq("resource")
      expect(presenter.to_xml.root["resourceClass"]).to eq("Project")
      expect(presenter.to_xml.root["resourceID"]).to eq(project.metadata_model.project_id)
      expect(presenter.to_xml.root["resourceIDType"]).to eq("DOI")
    end

    describe "<title>" do
      let(:title_node) { presenter.to_xml.root.at_xpath("title") }

      it "builds a <title> element containing the title of the project" do
        expect(title_node).to be_a(Nokogiri::XML::Element)
        expect(title_node.name).to eq("title")
        expect(title_node["inherited"]).to eq("false")
        expect(title_node["discoverable"]).to eq("true")
        expect(title_node["trackingLevel"]).to eq("ResourceRecord")
      end
    end
  end
end
