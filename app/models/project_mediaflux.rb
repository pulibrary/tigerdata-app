# frozen_string_literal: true

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
    # The namespace is directly under our root namespace
    project_name = safe_name(project.directory)
    project_namespace = "#{Rails.configuration.mediaflux['api_root_ns']}/#{project_name}NS"
    namespace = Mediaflux::Http::NamespaceCreateRequest.new(namespace: project_namespace, description: "Namespace for project #{project.title}", store: store_name, session_token: session_id)
    if namespace.error?
      raise "Can not create the namespace #{namespace.response_error}"
    end
    # Create a collection asset under the root namespace and set its metadata
    tigerdata_values = project_values(project: project)
    project_parent = Rails.configuration.mediaflux["api_root_collection"]
    prepare_parent_collection(project_parent:, session_id:)
    create_request = Mediaflux::Http::AssetCreateRequest.new(session_token: session_id, namespace: project_namespace, name: project_name, tigerdata_values: tigerdata_values,
                                                             xml_namespace: xml_namespace, pid: project_parent)

          #TODO: custom exception class raised for metadata issues. This would allow us to see them in Honeybadger and know how often they're happening. 
          #All exceptions that are raised should include the current expected metadata schema version number, as well as what metadata is missing.
    id = create_request.id
    if id.blank?
      response_xml = create_request.response_xml
      response_text = response_xml.text
      case response_text
      when "failed: The namespace #{project_namespace} already contains an asset named '#{project_name}'"
        raise "Project name already taken"
      when /'asset.create' failed/

        # Ensure that the metadata validations are run
        project.metadata_model.validate
        raise TigerData::MissingMetadata.missing_metadata(schema_version:"0.6", errors: project.metadata_model.errors)
      else
        raise(StandardError,"An error has occured during project creation, not related to namespace creation or collection creation")
      end
    end
    id
  end

  def self.update(project:, session_id:)
    tigerdata_values = project_values(project: project)
    Mediaflux::Http::AssetUpdateRequest.new(session_token: session_id, id: project.mediaflux_id, tigerdata_values: tigerdata_values).resolve
  end

  # This method is used for transforming iso8601 dates to dates that MediaFlux likes
  # Take a string like "2024-02-26T10:33:11-05:00" and convert this string to "22-FEB-2024 13:57:19"
  def self.format_date_for_mediaflux(iso8601_date)
    return if iso8601_date.nil?
    Time.parse(iso8601_date).strftime("%e-%b-%Y %H:%M:%S").upcase
  end

  # Translates database record into mediaflux meta document.
  # This is where the XML payload is generated.
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def self.project_values(project:)
    values = {
      code: project.directory,
      title: project.metadata[:title],
      description: project.metadata[:description],
      status: project.metadata[:status],
      data_sponsor: project.metadata[:data_sponsor],
      data_manager: project.metadata[:data_manager],
      data_user_read_only: project.metadata[:data_user_read_only],
      data_user_read_write: project.metadata[:data_user_read_write],
      departments: project.metadata[:departments],
      created_on: format_date_for_mediaflux(project.metadata[:created_on]),
      created_by: project.metadata[:created_by],
      updated_on: format_date_for_mediaflux(project.metadata[:updated_on]),
      updated_by: project.metadata[:updated_by],
      project_id: project.metadata[:project_id],
      storage_capacity: project.metadata[:storage_capacity_requested],
      storage_performance: project.metadata[:storage_performance_expectations_requested],
      project_purpose: project.metadata[:project_purpose]
    }
    values
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def self.xml_payload(project:, xml_namespace: nil)
    project_name = safe_name(project.directory)
    project_namespace = "#{Rails.configuration.mediaflux['api_root_ns']}/#{project_name}NS"
    project_parent = Rails.configuration.mediaflux["api_root_collection"]

    tigerdata_values = project_values(project: project)
    create_request = Mediaflux::Http::AssetCreateRequest.new(session_token: nil, namespace: project_namespace, name: project_name, tigerdata_values: tigerdata_values,
                                                             xml_namespace: xml_namespace, pid: project_parent)
    create_request.xml_payload
  end

  def self.document(project:, xml_namespace: nil)
    xml_body = xml_payload(project:, xml_namespace:)
    Nokogiri::XML.parse(xml_body)
  end

  def self.safe_name(name)
    # only alphanumeric characters
    name.strip.gsub(/[^A-Za-z\d]/, "-")
  end

  def self.create_root_ns(session_id:)
    root_namespace = Rails.configuration.mediaflux["api_root_ns"]
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
        get_parent = Mediaflux::Http::GetMetadataRequest.new(session_token: session_id, id: project_parent)
        if get_parent.error?
          if project_parent.include?("path=")
            create_parent_request = Mediaflux::Http::AssetCreateRequest.new(session_token: session_id, namespace: Rails.configuration.mediaflux["api_root_collection_namespace"],
                                                                            name: Rails.configuration.mediaflux["api_root_collection_name"])
            raise "Can not create parent collection: #{create_parent_request.response_error}" if create_parent_request.error?
          end
        end    
      end
  end
end
