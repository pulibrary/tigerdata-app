# frozen_string_literal: true
class ProjectMediaflux
  attr_accessor :id, :name, :path, :title, :organization, :file_count, :store_name,
    :data_sponsor

  def initialize(id, name, path, title, organization, store = nil, session_id:)
    @id = id
    @name = name
    @path = path
    @title = title
    @organization = organization
    @file_count = 0 # set on get()
    @store_name = store || Store.default(session_id: session_id).name # overwritten in get()
  end

  def files_paged(page_num, session_id:)
    page_size = 100
    idx = ((page_num - 1) * page_size) + 1
    query_request = Mediaflux::Http::QueryRequest.new(session_token: session_id, collection: id, size: page_size, idx: idx, action: "get-name")
    query_request.result
  end

  def add_new_files(count, session_id:)
    pattern = "#{name}-#{Time.zone.today}-#{Time.now.seconds_since_midnight.to_i}-"
    test_create_request = Mediaflux::Http::TestAssetCreateRequest.new(session_token: session_id, parent_id: id, count: count, pattern: pattern)
    test_create_request.error?
  end

  # rubocop:disable Metrics/MethodLength
  def self.create!(name, store_name, organization, session_id:)
    # Create a namespace for the project (within the namespace of the organization)...
    project_namespace = organization.path + "/" + safe_name(name) + "-ns"
    Mediaflux::Http::NamespaceCreateRequest.new(namespace: project_namespace, description: "Namespace for project #{name}", store: store_name, session_token: session_id).resolve

    # ...create a project as a collection asset inside this new namespace

    # TODO: Switch to user entered values
    values = {
      code: "project-123",
      title: "title of project 123",
      description: "description of project 123",
      data_sponsor: "hc123",
      data_manager: "zz123",
      departments: ["PUL", "PUL-RDSS"],
      created_on: "now",
      created_by: "hc8719"
    }

    create_request = Mediaflux::Http::CreateAssetRequest.new(session_token: session_id, namespace: project_namespace, name: safe_name(name), tigerdata_values: values)
    get_request = Mediaflux::Http::GetMetadataRequest.new(session_token: session_id, id: create_request.id)
    collection_asset = get_request.metadata
    ProjectMediaflux.new(collection_asset[:id], collection_asset[:name], collection_asset[:path], collection_asset[:description], organization, store_name, session_id: session_id)
  end
  # rubocop:enable Metrics/MethodLength

  def self.get(id, session_id:, organization: nil)
    # Fetch the collection asset for the project...
    get_request = Mediaflux::Http::GetMetadataRequest.new(session_token: session_id, id: id)
    collection_asset = get_request.metadata

    # ...fetch the namespace for the project (one level up)
    namespace_request = Mediaflux::Http::NamespaceDescribeRequest.new(path: collection_asset[:namespace], session_token: session_id)
    project_ns = namespace_request.metadata

    # ...find the org for this collection (which is the namespace two levels up)
    #  No need to reload the orgnaization if it is known
    if organization.nil?
      org_path = File.dirname(collection_asset[:namespace])
      organization = Organization.get(nil, session_id: session_id, path: org_path)
    end

    project = ProjectMediaflux.new(collection_asset[:id], collection_asset[:name], collection_asset[:path], collection_asset[:description], organization, session_id: session_id)
    project.file_count = collection_asset[:total_file_count]
    project.store_name = project_ns[:store]

    project
  end

  def self.by_organization(org, session_id:)
    projects = []

    namespace_request = Mediaflux::Http::NamespaceListRequest.new(session_token: session_id, parent_namespace: org.path)
    org_namespaces = namespace_request.namespaces
    org_namespaces.each do |ns|
      path = org.path + "/" + ns[:name]
      collection_request = Mediaflux::Http::CollectionQueryRequest.new(session_token: session_id, namespace: path)
      collection = collection_request.collections.first
      projects << ProjectMediaflux.get(collection[:id], session_id: session_id, organization: org)
    end
    projects
  end

  def self.safe_name(name)
    # only alphanumeric characters
    name.gsub(/[^A-Za-z\d]/, "-")
  end
end
