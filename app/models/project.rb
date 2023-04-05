# frozen_string_literal: true
class Project
  attr_accessor :id, :name, :path, :organization

  def initialize(id, name, path, organization)
    @id = id
    @name = name
    @path = path
    @organization = organization
  end

  # The project is always a child of the organization
  def self.create!(name, organization)
    media_flux = MediaFluxClient.default_instance
    id = media_flux.create_collection_asset(organization.path, safe_name(name))
    collection_asset = media_flux.get_metadata(id)
    media_flux.logout
    Project.new(collection_asset[:id], collection_asset[:name], collection_asset[:path], organization)
  end

  def self.get(id)
    media_flux = MediaFluxClient.default_instance
    collection_asset = media_flux.get_metadata(id)
    media_flux.logout
    organization = Organization.get(collection_asset[:namespace_id])
    Project.new(collection_asset[:id], collection_asset[:name], collection_asset[:path], organization)
  end

  def self.by_organization(org)
    media_flux = MediaFluxClient.default_instance
    namespaces = media_flux.namespace_collection_assets(org.path)
    media_flux.logout
    projects = []
    namespaces.each do |namespace|
      name =
      projects << Project.new(namespace[:id], namespace[:name], namespace[:path], org)
    end
    projects
  end

  def files
    @files ||= begin
      media_flux = MediaFluxClient.default_instance
      page_results = media_flux.query_collection(id, idx: 1, size: 100)
      media_flux.logout
      page_results
    end
  end

  def self.safe_name(name)
    # only alphanumeric characters
    name.gsub(/[^A-Za-z\d]/, "-")
  end
end
