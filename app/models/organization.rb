# frozen_string_literal: true
class Organization
  attr_accessor :id, :name, :path

  def initialize(id, name, path)
    @id = id
    @name = name
    @path = path
  end

  def projects
    # TODO: memoize this value
    Project.by_organization(self)
  end

  def self.get(id)
    media_flux = MediaFluxClient.default_instance
    namespace = media_flux.namespace_describe(id)
    media_flux.logout
    org = Organization.new(namespace[:id], namespace[:name], namespace[:path])
    org
  end

  def self.create!(name)
    media_flux = MediaFluxClient.default_instance
    id = nil

    namespace_fullname = Rails.configuration.mediaflux["api_root_ns"] + "/" + name
    if media_flux.namespace_exists?(namespace_fullname)
      Rails.logger.info "Namespace #{namespace_fullname} already exists"
      id = nil # TODO get the id
    else
      Rails.logger.info "Created namespace #{namespace_fullname}"
      id = media_flux.namespace_create(namespace_fullname)
    end

    media_flux.logout
    id
  end

  def self.list
    media_flux = MediaFluxClient.default_instance
    root_namespace = Rails.configuration.mediaflux["api_root_ns"]
    data = media_flux.namespace_list(root_namespace)

    # Horrible hack until we create a rake task to seed the server
    if data.count == 0
      self.create_defaults
      data = media_flux.namespace_list(root_namespace)
    end

    media_flux.logout
    data
  end

  def self.create_root_ns
    media_flux = MediaFluxClient.default_instance
    root_namespace = Rails.configuration.mediaflux["api_root_ns"]
    if media_flux.namespace_exists?(root_namespace)
      Rails.logger.info "Root namespace #{root_namespace} already exists"
    else
      Rails.logger.info "Created root namespace #{root_namespace}"
      media_flux.namespace_create(root_namespace)
    end
    media_flux.logout
  end

  def self.create_defaults
    create_root_ns
    organizations = ["rc", "pppl", "pul"]
    organizations.each do |code|
      Organization.create!(code)
    end
  end
end
