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
      ProjectAccumulator.new(project: project, session_id: session_id).create!()
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
    session_id = user.mediaflux_session
    store_name = Store.default(session_id: session_id).name

    # Make sure the root namespace and the required nodes below it exist.
    create_root_tree(session_id: session_id)

    # Create a namespace for the project
    # The namespace is directly under our root namespace'
    project_name = project.project_directory
    project_namespace = "#{project_name}NS"
    namespace = Mediaflux::NamespaceCreateRequest.new(namespace: project_namespace, description: "Namespace for project #{project.title}", store: store_name, session_token: session_id)
    if namespace.error?
      raise MediafluxDuplicateNamespaceError.new("Can not create the namespace #{namespace.response_error}")
    end
    # Create a collection asset under the root namespace and set its metadata
    project_parent = Mediaflux::Connection.root_collection
    create_request = Mediaflux::ProjectCreateRequest.new(session_token: session_id, namespace: project_namespace, project:, xml_namespace: xml_namespace, pid: project_parent)
    id = create_request.id
    if id.blank?
      response_error = create_request.response_error
      case response_error[:message]
      when "failed: The namespace #{project_namespace} already contains an asset named '#{project_name}'"
        raise "Project name already taken"
      when /'asset.create' failed/

        # Ensure that the metadata validations are run
        if project.valid?
          raise response_error[:message]  # something strange went wrong
        else
          raise TigerData::MissingMetadata.missing_metadata(schema_version: ::TigerdataSchema::SCHEMA_VERSION, errors: project.errors)
        end
      else
        raise(StandardError,"An error has occured during project creation, not related to namespace creation or collection creation")
      end
    end

    # Save the ActiveRecord to make sure the mediaflux_id is recorded
    project.mediaflux_id = id
    project.save!

    id
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
