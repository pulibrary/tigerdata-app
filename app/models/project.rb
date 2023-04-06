# frozen_string_literal: true
class Project
  attr_accessor :id, :name, :path, :title, :organization, :file_count

  def initialize(id, name, path, title, organization)
    @id = id
    @name = name
    @path = path
    @title = title
    @organization = organization
    @file_count = 0
  end

  def files
    @files ||= begin
      media_flux = MediaFluxClient.default_instance
      page_results = media_flux.query_collection(id, idx: 1, size: 100)
      media_flux.logout
      page_results
    end
  end

  def add_new_files(count)
    pattern = "#{name}-#{Date.today}-#{Time.now.seconds_since_midnight.to_i}-"
    media_flux = MediaFluxClient.default_instance
    media_flux.add_new_files_to_collection(id, count, pattern)
    media_flux.logout
  end

  # The project is always a child of the organization
  def self.create!(name, organization)
    media_flux = MediaFluxClient.default_instance
    id = media_flux.create_collection_asset(organization.path, safe_name(name), name)
    collection_asset = media_flux.get_metadata(id)
    media_flux.logout
    Project.new(collection_asset[:id], collection_asset[:name], collection_asset[:path], collection_asset[:description], organization)
  end

  def self.get(id)
    media_flux = MediaFluxClient.default_instance
    collection_asset = media_flux.get_metadata(id)
    media_flux.logout
    organization = Organization.get(collection_asset[:namespace_id])
    project = Project.new(collection_asset[:id], collection_asset[:name], collection_asset[:path], collection_asset[:description], organization)
    project.file_count = collection_asset[:total_file_count]
    project
  end

  def self.by_organization(org)
    media_flux = MediaFluxClient.default_instance
    namespaces = media_flux.namespace_collection_assets(org.path)
    media_flux.logout
    projects = []
    namespaces.each do |namespace|
      name =
      projects << Project.new(namespace[:id], namespace[:name], namespace[:path], namespace[:description], org)
    end
    projects
  end

  def self.safe_name(name)
    # only alphanumeric characters
    name.gsub(/[^A-Za-z\d]/, "-")
  end
end
