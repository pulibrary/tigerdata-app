# frozen_string_literal: true
namespace :schema do
  # Define the TigerData schema
  task create: :environment do
    # TODO: Make sure we login with a user that has access to
    # asset.doc.type.update and asset.doc.type.update
    logon_request = Mediaflux::Http::LogonRequest.new
    logon_request.resolve
    schema = TigerdataSchema.new(session_id: logon_request.session_token)
    schema.create
  end

  # TODO: Remove this rake task before merging.
  # This is what I used to figure out the right Nokogiri syntax to generate the
  # XML that MediaFlux expects.
  task xml_generation: :environment do
    xml_doc = Nokogiri::XML::Builder.new do |xml|
      xml.request do
        xml.service(name: "asset.set", session: "123") do
          xml.args do
            xml.namespace "hello_ns"
            xml.meta do
              xml.send("tigerdata:simple", "xmlns:tigerdata" => "tigerdata") do
                xml.data_sponsor "hc8719"
              end
            end
          end
        end
      end
    end

    target = <<-XML
<args>
  <id>1096</id>
  <meta>
    <tigerdata:simple xmlns:tigerdata="tigerdata">
      <data_sponsor>hc8719</data_sponsor>
     </tigerdata:simple>
  </meta>
</args>
    XML
    puts "TARGET"
    puts target
    puts "==="
    puts xml_doc.to_xml
    puts "==="
  end
end
