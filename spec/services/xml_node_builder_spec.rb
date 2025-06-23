# frozen_string_literal: true
require "rails_helper"

describe XmlNodeBuilder do
  describe "#build" do
    subject(:xml_builder) { described_class.new(document: document) }
    let(:document) { Nokogiri::XML::Document.new }
    let(:built) { xml_builder.build }

    it "returns the document" do
      expect(built).to be nil
    end

    context "when the document has a root element" do
      before do
        document.root = Nokogiri::XML::Element.new("root", document)
      end

      it "returns the root element" do
        expect(built).to eq(document.root)
      end
    end
  end
end
