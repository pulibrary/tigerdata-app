# frozen_string_literal: true
class Project
  attr_accessor :id, :name, :path, :title, :organization, :file_count, :store_name

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

  def self.create!(name, store_name, organization, session_id:)
    # Create a namespace for the project (within the namespace of the organization)...
    project_namespace = organization.path + "/" + safe_name(name) + "-ns"
    Mediaflux::Http::NamespaceCreateRequest.new(namespace: project_namespace, description: "Namespace for project #{name}", store: store_name, session_token: session_id).resolve

    # ...create a project as a collection asset inside this new namespace
    create_request = Mediaflux::Http::CreateAssetRequest.new(session_token: session_id, namespace: project_namespace, name: safe_name(name))
    get_request = Mediaflux::Http::GetMetadataRequest.new(session_token: session_id, id: create_request.id)
    collection_asset = get_request.metadata
    Project.new(collection_asset[:id], collection_asset[:name], collection_asset[:path], collection_asset[:description], organization, store_name, session_id: session_id)
  end

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

    project = Project.new(collection_asset[:id], collection_asset[:name], collection_asset[:path], collection_asset[:description], organization, session_id: session_id)
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
      projects << Project.get(collection[:id], session_id: session_id, organization: org)
    end
    projects
  end

  def self.safe_name(name)
    # only alphanumeric characters
    name.gsub(/[^A-Za-z\d]/, "-")
  end

  def self.schema_fields
    # TODO: I think these fields should be their own Ruby class and we can make them
    # a little bit more friendly (e.g. required, optional, et ceterea) rather than using
    # the MediaFlux lingo (e.g. min-occurs, max-occurs)
    id = { name: "id", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The unique identifier for the project" }
    title = { name: "title", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "A plain-language title for the project" }
    description = { name: "description", type: "string", index: false, "min-occurs" => 1, "max-occurs" => 1, label: "A brief description of the project" }
    data_sponsor = { name: "data_sponsor", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The person who takes primary responsibility for the project" }
    data_manager = { name: "data_manager", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "The person who manages the day-to-day activities for the project" }
    data_users_rw = { name: "data_users_rw", type: "string", index: true, "min-occurs" => 0, label: "A person who has read and write access privileges to the project" }
    data_users_ro = { name: "data_users_ro", type: "string", index: true, "min-occurs" => 0, label: "A person who has read-only access privileges to the project" }
    departments = { name: "departments", type: "string", index: true, "min-occurs" => 1, label: "The primary Princeton University department(s) affiliated with the project" }
    created_on = { name: "created_on", type: "date", index: false, "min-occurs" => 1, label: "Timestamp project was created" }
    created_by = { name: "created_by", type: "string", index: false, "min-occurs" => 1, label: "User that created the project" }
    [id, title, description, data_sponsor, data_manager, data_users_rw, data_users_ro, departments, created_on, created_by]
  end

  def self.create_schema(session_id:)
    # Create the TigerData schema namespace
    # TODO: Add validation so that it only creates it if it does not exist
    # TODO: This should probably exist outside of the Projects class
    #       since it will hold information for other "document types"
    schema_name = "tigerdata"
    description = "TigerData Metadata"
    schema_request = Mediaflux::Http::SchemaCreateRequest.new(name: schema_name, description: description,
                                                              session_token: session_id)
    schema_request.resolve

    # ...and add the schema for Projects
    fields_request = Mediaflux::Http::SchemaFieldsCreateRequest.new(
      schema_name: schema_name,
      document: "project",
      description: "Project Metadata",
      fields: schema_fields,
      session_token: session_id
    )
    fields_request.resolve
  end
end
