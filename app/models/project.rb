# frozen_string_literal: true
class Project
  attr_accessor :id, :name, :path

  def initialize(id, name, path)
    @id = id
    @name = name
    @path = path
  end

  def self.by_organization(org_path)
    media_flux = MediaFluxClient.default_instance
    namespaces = media_flux.namespace_collection_assets(org_path)
    media_flux.logout
    projects = []
    namespaces.each do |namespace|
      projects << Project.new(namespace[:id], namespace[:name], namespace[:path])
    end
    projects
  end
end
