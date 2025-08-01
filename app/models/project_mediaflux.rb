# frozen_string_literal: true

# A custom exception class for when a namespace path is already taken
class MediafluxDuplicateNamespaceError < StandardError
end

# Take an instance of Project and adds it to MediaFlux
class ProjectMediaflux
  # Returns the XML string with the mediaflux metadata
  def self.xml_payload(project:, user:, xml_namespace: nil)
    request = Mediaflux::AssetMetadataRequest.new(session_token: user.mediaflux_session, id: project.mediaflux_id)
    request.resolve
    request.response_body
  end

  # Returns an XML document with the mediaflux metadata
  def self.document(project:, user:, xml_namespace: nil)
    xml_body = xml_payload(project:, user:, xml_namespace:)
    Nokogiri::XML.parse(xml_body)
  end
end
