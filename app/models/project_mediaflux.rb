# frozen_string_literal: true

# A custom exception class for when a namespace path is already taken
class MediafluxDuplicateNamespaceError < StandardError
end

# Take an instance of Project and adds it to MediaFlux
# Handles interactions with Mediaflux for projects.
class ProjectMediaflux
  # Retrieves the XML payload with Mediaflux metadata for a project.
  # @param project [Project] the project instance.
  # @param user [User] the user for session.
  # @param xml_namespace [String, nil] optional XML namespace.
  # @return [String] the XML string.
  # @raise [StandardError] if request errors.
  def self.xml_payload(project:, user:, xml_namespace: nil)
    request = Mediaflux::AssetMetadataRequest.new(session_token: user.mediaflux_session, id: project.mediaflux_id)
    request.resolve
    if request.error?
      raise request.response_error[:message]
    end
    request.response_body
  end

  # Retrieves an XML document with Mediaflux metadata.
  # @param project [Project] the project instance.
  # @param user [User] the user for session.
  # @param xml_namespace [String, nil] optional XML namespace.
  # @return [Nokogiri::XML::Document] the parsed XML document.
  def self.document(project:, user:, xml_namespace: nil)
    xml_body = xml_payload(project:, user:, xml_namespace:)
    Nokogiri::XML.parse(xml_body)
  end
end
