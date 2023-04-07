# frozen_string_literal: true
class Organization
  attr_accessor :id, :name, :path, :title, :store

  def initialize(id, name, path, title)
    @id = id
    @name = name
    @path = path
    @title = title
    @store = nil # set on get
  end

  def projects
    # TODO: memoize this value
    Project.by_organization(self)
  end

  def self.get(id)
    media_flux = MediaFluxClient.default_instance
    namespace = media_flux.namespace_describe(id)
    media_flux.logout
    org = Organization.new(namespace[:id], namespace[:name], namespace[:path], namespace[:description])
    org.store = Store.get_by_name(namespace[:store])
    org
  end

  def self.create!(name, title)
    media_flux = MediaFluxClient.default_instance
    id = nil

    namespace_fullname = Rails.configuration.mediaflux["api_root_ns"] + "/" + name
    if media_flux.namespace_exists?(namespace_fullname)
      Rails.logger.info "Namespace #{namespace_fullname} already exists"
      id = nil # TODO get the id
    else
      Rails.logger.info "Created namespace #{namespace_fullname}"
      id = media_flux.namespace_create(namespace_fullname, title, "data")
    end

    media_flux.logout
    id
  end

  def self.list
    media_flux = MediaFluxClient.default_instance
    root_namespace = Rails.configuration.mediaflux["api_root_ns"]
    namespace_list = media_flux.namespace_list(root_namespace)

    # Horrible hack until we create a rake task to seed the server
    if namespace_list.count == 0
      self.create_defaults
      namespace_list = media_flux.namespace_list(root_namespace)
    end

    organizations = namespace_list.map { |ns| Organization.get(ns[:id]) }

    media_flux.logout
    organizations
  end

  def self.create_root_ns
    media_flux = MediaFluxClient.default_instance
    root_namespace = Rails.configuration.mediaflux["api_root_ns"]
    if media_flux.namespace_exists?(root_namespace)
      Rails.logger.info "Root namespace #{root_namespace} already exists"
    else
      Rails.logger.info "Created root namespace #{root_namespace}"
      media_flux.namespace_create(root_namespace, "TigerData root namespace", Store.all.first.name)
    end
    media_flux.logout
  end

  def self.create_defaults
    create_root_ns
    organizations = []
    organizations << {name: "rc", title: "Research Computing"}
    organizations << {name: "pppl", title: "Princeton Physics Plasma Lab"}
    organizations << {name: "pul", title: "Princeton University Library"}
    organizations.each do |org|
      Organization.create!(org[:name], org[:title])
    end
  end
end
