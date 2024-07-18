# frozen_string_literal: true

# A custom exception class for when a namespace path is already taken
class MediafluxDuplicateNamespaceError < StandardError
end

# Take an instance of Project and adds it to MediaFlux
class ProjectMediaflux
  # If the project hasn't yet been created in mediaflux, create it.
  # If it already exists, update it.
  # @return [String] the mediaflux id of the project
  def self.save(project:, session_id:, xml_namespace: nil)
    if project.mediaflux_id.nil?
      mediaflux_id = ProjectMediaflux.create!(project: project, session_id: session_id)
      ProjectAccumulator.new(project: project, session_id: session_id).create!()
      project.reload
      Rails.logger.debug "Project #{project.id} has been created in MediaFlux (asset id #{mediaflux_id})"
    else
      ProjectMediaflux.update(project: project, session_id: session_id)
      Rails.logger.debug "Project #{project.id} has been updated in MediaFlux (asset id #{project.mediaflux_id})"
    end
    project.mediaflux_id
  end

  # Create a project in MediaFlux
  #
  # @param project [Project] the project that needs to be added to MediaFlux
  # @param session_id [] the session id for the user who is currently authenticated to MediaFlux
  # @param xml_namespace []
  # @return [String] The id of the project that got created
  def self.create!(project:, session_id:, xml_namespace: nil)
    store_name = Store.default(session_id: session_id).name

    # Make sure the root namespace exists
    create_root_ns(session_id: session_id)

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
    prepare_parent_collection(project_parent:, session_id:)
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
    project.mediaflux_id = id
    project.save!

    id
  end

  def self.update(project:, session_id:)
    Mediaflux::ProjectUpdateRequest.new(session_token: session_id, project: project).resolve
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

  def self.create_root_ns(session_id:)
    root_namespace = Mediaflux::Connection.root_namespace
    namespace_request = Mediaflux::NamespaceDescribeRequest.new(path: root_namespace, session_token: session_id)
    if namespace_request.exists?
      Rails.logger.info "Root namespace #{root_namespace} already exists"
    else
      Rails.logger.info "Created root namespace #{root_namespace}"
      namespace_request = Mediaflux::NamespaceCreateRequest.new(namespace: root_namespace, description: "TigerData client app root namespace",
                                                                      store: Store.all(session_id: session_id).first.name,
                                                                      session_token: session_id)
      namespace_request.response_body
    end
  end

  class << self

    private
      def prepare_parent_collection(project_parent:, session_id:)
        get_parent = Mediaflux::AssetMetadataRequest.new(session_token: session_id, id: project_parent)
        if get_parent.error?
          if project_parent.include?("path=")
            create_parent_request = Mediaflux::AssetCreateRequest.new(session_token: session_id, namespace: Mediaflux::Connection.root_collection_namespace,
                                                                            name: Mediaflux::Connection.root_collection_name)
            raise "Can not create parent collection: #{create_parent_request.response_error}" if create_parent_request.error?
          end
        end
      end
  end
end
