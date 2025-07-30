# frozen_string_literal: true

# A custom exception class for when a namespace path is already taken
class MediafluxDuplicateNamespaceError < StandardError
end

# Take an instance of Project and adds it to MediaFlux
class ProjectMediaflux
  # If the project hasn't yet been created in mediaflux, create it.
  # If it already exists, update it.
  # @return [String] the mediaflux id of the project
  def self.save(project:, user:, xml_namespace: nil)
    session_id = user.mediaflux_session
    if project.mediaflux_id.nil?
      mediaflux_id = project.approve!(current_user: user)
      Rails.logger.debug "Project #{project.id} has been created in MediaFlux (asset id #{mediaflux_id})"
    else
      ProjectMediaflux.update(project: project, user: user)
      Rails.logger.debug "Project #{project.id} has been updated in MediaFlux (asset id #{project.mediaflux_id})"
    end
    project.reload
    project.mediaflux_id
  end

  # # Create a project in MediaFlux
  # #
  # # @param project [Project] the project that needs to be added to MediaFlux
  # # @param session_id [] the session id for the user who is currently authenticated to MediaFlux
  # # @param xml_namespace []
  # # @return [String] The id of the project that got created
  # def self.create!(project:, user:, xml_namespace: nil)
  #   project.approve!(current_user: user)
  #   project.mediaflux_id
  # end

  def self.update(project:, user:)
    raise "Update in Mediaflux has not been implemented"
  end

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
