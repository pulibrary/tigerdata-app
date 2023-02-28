# frozen_string_literal: true
require "nokogiri"
require "xml_utilities"

describe "xml_utilities" do
  it "translates xml to hash" do
    expect(xml_to_hash(Nokogiri("<a></a>"))).to eq({ kind: "element", name: "a" })
  end
end
