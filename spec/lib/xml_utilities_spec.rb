require 'xml_utilities'

describe "xml_utilities" do
      it "translates xml to hash" do
        expect(xml_to_hash(Nokogiri('<a></a>'))).to eq({})
      end
    end