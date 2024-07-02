# frozen_string_literal: true

# A custom exception class for when a namespace path is already taken
class MediafluxDuplicateNamespaceError < StandardError
end

# Take an instance of Project and adds it to MediaFlux
class ProjectMediaflux
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
    namespace = Mediaflux::Http::NamespaceCreateRequest.new(namespace: project_namespace, description: "Namespace for project #{project.title}", store: store_name, session_token: session_id)
    if namespace.error?
      raise MediafluxDuplicateNamespaceError.new("Can not create the namespace #{namespace.response_error}")
    end
    # Create a collection asset under the root namespace and set its metadata
    project_parent = Mediaflux::Http::Connection.root_collection
    prepare_parent_collection(project_parent:, session_id:)
    create_request = Mediaflux::Http::ProjectCreateRequest.new(session_token: session_id, namespace: project_namespace, project:, xml_namespace: xml_namespace, pid: project_parent)
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

    self.create_quota(project: project, mediaflux_project_id: id, session_id: session_id)
    id
  end

  # Generates the quota during project creation 
  def self.create_quota(project:, mediaflux_project_id:, session_id:)
    #TODO: SHOULD WE CREATE A PROJECT USING REQUESTED VALUES OR APPROVED VALUES?
    allocation = project.metadata_json["storage_capacity"]["size"]["requested"].to_s << " " << project.metadata_json["storage_capacity"]["unit"]["requested"]
      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param collection [String] Id of the collection
      # @param allocation [String] Quota allocation to be set for the collection, e.g. "1 MB" or "1 GB"
      def quota_request(session_token:, collection:, allocation:)
        super(session_token: session_token)
        @collection = collection
        @allocation = allocation
        @name = "#{@allocation} quota for #{@collection}"
        quota_request.resolve
      end

      # Specifies the Mediaflux service to use when creating assets
      # @return [String]
      def self.service
        "asset.collection.quota.set"
      end
  end

  def self.update(project:, session_id:)
    Mediaflux::Http::ProjectUpdateRequest.new(session_token: session_id, project: project).resolve
  end

  def self.xml_payload(project:, xml_namespace: nil)
    project_name = project.project_directory
    project_namespace = "#{project_name}NS"
    project_parent = Mediaflux::Http::Connection.root_collection

    create_request = Mediaflux::Http::ProjectCreateRequest.new(session_token: nil, namespace: project_namespace, project:, xml_namespace: xml_namespace, pid: project_parent)
    create_request.xml_payload
  end

  def self.document(project:, xml_namespace: nil)
    xml_body = xml_payload(project:, xml_namespace:)
    Nokogiri::XML.parse(xml_body)
  end

  def self.create_root_ns(session_id:)
    root_namespace = Mediaflux::Http::Connection.root_namespace
    namespace_request = Mediaflux::Http::NamespaceDescribeRequest.new(path: root_namespace, session_token: session_id)
    if namespace_request.exists?
      Rails.logger.info "Root namespace #{root_namespace} already exists"
    else
      Rails.logger.info "Created root namespace #{root_namespace}"
      namespace_request = Mediaflux::Http::NamespaceCreateRequest.new(namespace: root_namespace, description: "TigerData client app root namespace",
                                                                      store: Store.all(session_id: session_id).first.name,
                                                                      session_token: session_id)
      namespace_request.response_body
    end
  end

  class << self

    private
      def prepare_parent_collection(project_parent:, session_id:)
        get_parent = Mediaflux::Http::AssetMetadataRequest.new(session_token: session_id, id: project_parent)
        if get_parent.error?
          if project_parent.include?("path=")
            create_parent_request = Mediaflux::Http::AssetCreateRequest.new(session_token: session_id, namespace: Mediaflux::Http::Connection.root_collection_namespace,
                                                                            name: Mediaflux::Http::Connection.root_collection_name)
            raise "Can not create parent collection: #{create_parent_request.response_error}" if create_parent_request.error?
          end
        end
      end

      # The generated XML mimics what we get when we issue an Aterm command as follows:
      # > asset.collection.quota.set :id 1282 :quota
      #     < :allocation 1 MB :on-overflow fail :description "1 MB quota for 1282" >
      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.id @collection
            xml.quota do
              xml.allocation @allocation
              xml.description @name
            end
          end
        end
      end
  end
end
