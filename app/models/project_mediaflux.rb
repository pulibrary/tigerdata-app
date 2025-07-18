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
      mediaflux_id = ProjectMediaflux.create!(project: project, user: user)
      Rails.logger.debug "Project #{project.id} has been created in MediaFlux (asset id #{mediaflux_id})"
    else
      ProjectMediaflux.update(project: project, user: user)
      Rails.logger.debug "Project #{project.id} has been updated in MediaFlux (asset id #{project.mediaflux_id})"
    end
    project.reload
    project.mediaflux_id
  end

  # Create a project in MediaFlux
  #
  # @param project [Project] the project that needs to be added to MediaFlux
  # @param session_id [] the session id for the user who is currently authenticated to MediaFlux
  # @param xml_namespace []
  # @return [String] The id of the project that got created
  def self.create!(project:, user:, xml_namespace: nil)
    project.approve!(current_user: user)
    project.mediaflux_id
  end

  def self.update(project:, user:)
    session_id = user.mediaflux_session
    project.metadata_model.updated_on ||= Time.current.in_time_zone("America/New_York").iso8601
    project.metadata_model.updated_by ||= user.uid
    update_request = Mediaflux::ProjectUpdateRequest.new(session_token: session_id, project: project)
    update_request.resolve
    raise update_request.response_error[:message] if update_request.error?

    # Save the ActiveRecord to make sure the updated metadata is also saved in our PostgreSQL database
    project.save!
  end

  def self.xml_payload(project:, xml_namespace: nil)
    project_name = project.project_directory
    project_namespace = "#{project_name}NS"
    project_parent = Mediaflux::Connection.root_collection

    create_request = Mediaflux::ProjectCreateRequest.new(session_token: nil, namespace: project_namespace, project:, xml_namespace: xml_namespace, pid: project_parent)
    create_request.xml_payload
  end

  def self.document(project:, xml_namespace: nil)
    xml_body = xml_payload(project:, xml_namespace:)
    Nokogiri::XML.parse(xml_body)
  end

  def self.create_root_tree(session_id:)
    root_ns = Rails.configuration.mediaflux["api_root_collection_namespace"]
    parent_collection = Rails.configuration.mediaflux["api_root_collection_name"]
    req = Mediaflux::RootCollectionAsset.new(session_token: session_id, root_ns:, parent_collection:)
    req.create
  end
end
