# frozen_string_literal: true
# :nocov:
require "nokogiri"
namespace :xml_schema do
  desc "Validates the example XML provided by Matt against the TigerData XSD"
  task validate_example: :environment do
    # Files downloaded from https://github.com/pulibrary/tigerdata-app/issues/896
    schema_file = "./lib/assets/TigerData_StandardMetadataSchema_v0.7_2024-08-27.xsd"
    document_file = "./lib/assets/TigerData_MetadataExample-Project_2024-08-27.xml"

    xsd = File.read(schema_file)
    xsd = use_local_xml_xsd(xsd)

    # Validate the sample XML file against the schema
    # https://www.tutorialspoint.com/xsd/xsd_syntax.htm
    # https://nokogiri.org/rdoc/Nokogiri/XML/Schema.html
    xsd = Nokogiri::XML::Schema(xsd)
    doc = Nokogiri::XML(File.read(document_file))
    errors = xsd.validate(doc)
    if errors.count == 0
      puts "OK"
    else
      errors.each do |error|
        puts error.message
      end
    end
  end

  # Replace the reference to `xml.xsd` from the xsd with a reference to our
  # local copy of the file, otherwise the validation tends to fail because
  # Nokogiri cannot load the original `xml.xsd` file from the W3C
  # source. ¯\_(ツ)_/¯
  # For more information see: https://stackoverflow.com/a/18527198/446681
  def use_local_xml_xsd(xsd)
    local_xml_xsd = Pathname.new("./lib/assets/xml.xsd").realpath.to_s
    xsd.sub!("https://www.w3.org/2001/xml.xsd", "file://#{local_xml_xsd}")
  end
end
# :nocov:
