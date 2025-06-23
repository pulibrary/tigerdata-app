# frozen_string_literal: true
require "rails_helper"

describe XmlNullBuilder do
  describe "#build" do
    subject(:null_builder) { described_class.new }

    it "returns an empty document" do
      expect(null_builder.build).to be_a(Nokogiri::XML::Document)
    end

    it "is blank" do
      expect(null_builder.blank?).to be true
    end

    it "does not add children" do
      expect(null_builder.add_child("child")).to be_nil
    end

    it "has no name" do
      expect(null_builder.name).to be_nil
    end
  end
end
