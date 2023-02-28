# frozen_string_literal: true
require "nokogiri"
require "xml_utilities"

describe "xml_utilities" do
  it "translates xml to hash" do
    expect(xml_doc_to_hash(Nokogiri("<a></a>"))).to eq({ name: "a" })
  end

  it "translates xml to hash" do
    expect(xml_doc_to_html(Nokogiri("<a></a>"))).to eq("<pre>:name: a\n</pre>")
  end

  it "translates asset type definition to hash" do
    expect(xml_doc_to_html(Nokogiri('<definition><element name="my_string" type="string" /></definition>'))).to eq("<pre>:name: definition\n:subelements:\n- :name: element\n  :attr:\n  - :name: name (attribute)\n    :text: my_string\n  - :name: type (attribute)\n    :text: string\n</pre>")
  end
end
