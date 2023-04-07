# frozen_string_literal: true
class Project
  attr_accessor :id, :name, :path, :title, :organization, :file_count, :store_name

  def initialize(id, name, path, title, organization)
    @id = id
    @name = name
    @path = path
    @title = title
    @organization = organization
    @file_count = 0 # set on get()
    @store_name = "data" # default to data, overwritten in get()
  end

  def files
    @files ||= begin
      media_flux = MediaFluxClient.default_instance
      page_results = media_flux.collection_query(id, idx: 1, size: 100)
      media_flux.logout
      page_results
    end
  end

  def files_paged(page_num)
    page_size = 100
    idx = ((page_num-1) * page_size) + 1
    media_flux = MediaFluxClient.default_instance
    page_results = media_flux.collection_query(id, idx: idx, size: page_size)
    media_flux.logout
    page_results
  end

  def add_new_files(count)
    pattern = "#{name}-#{Date.today}-#{Time.now.seconds_since_midnight.to_i}-"
    media_flux = MediaFluxClient.default_instance
    media_flux.add_new_files_to_collection(id, count, pattern)
    media_flux.logout
  end

  def self.create!(name, store_name, organization)
    media_flux = MediaFluxClient.default_instance
    # Create a namespace for the project (within the namespace of the organization)...
    project_namespace = organization.path + "/" + safe_name(name) + "-ns"
    media_flux.namespace_create(project_namespace, "Namespace for project #{name}", store_name)
    # ...create a project as a collection asset inside this new namespace
    id = media_flux.create_collection_asset(project_namespace, safe_name(name), name)
    collection_asset = media_flux.get_metadata(id)
    media_flux.logout
    Project.new(collection_asset[:id], collection_asset[:name], collection_asset[:path], collection_asset[:description], organization)
  end

  def self.get(id)
    media_flux = MediaFluxClient.default_instance

    # Fetch the collection asset for the project...
    collection_asset = media_flux.get_metadata(id)

    # ...fetch the namespace for the project (one level up)
    project_ns = media_flux.namespace_describe_by_name(collection_asset[:namespace])

    # ...find the org for this collection (which is the namespace two levels up)
    org_path = File.dirname(collection_asset[:namespace])
    organization_ns = media_flux.namespace_describe_by_name(org_path)
    organization = Organization.get(organization_ns[:id])

    project = Project.new(collection_asset[:id], collection_asset[:name], collection_asset[:path], collection_asset[:description], organization)
    project.file_count = collection_asset[:total_file_count]
    project.store_name = project_ns[:store]

    media_flux.logout
    project
  end

  def self.by_organization(org)
    media_flux = MediaFluxClient.default_instance
    projects = []
    org_namespaces = media_flux.namespace_list(org.path)
    org_namespaces.each do |ns|
      path = org.path + "/" + ns[:name]
      collection = media_flux.namespace_collection_assets(path).first
      projects << Project.get(collection[:id])
    end
    projects
  end

  def self.safe_name(name)
    # only alphanumeric characters
    name.gsub(/[^A-Za-z\d]/, "-")
  end
end
