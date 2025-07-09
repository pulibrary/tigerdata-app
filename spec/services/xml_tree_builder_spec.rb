# frozen_string_literal: true
require "rails_helper"

describe XmlTreeBuilder do
  describe "#build" do
    subject(:xml_builder) { described_class.new(children: children, presenter: presenter, name: name) }
    let(:children) { [] }
    let(:presenter) { double("Presenter") }
    let(:name) { "child1" }

    let(:built) { xml_builder.build }
    it "returns an empty XML string when no elements are added" do
      expect(built).to be_a(Nokogiri::XML::Element)
      expect(built.name).to eq(name)
    end
  end
end
