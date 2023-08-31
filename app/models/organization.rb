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

  def projects(session_id:)
    @projects ||= Project.by_organization(self, session_id: session_id)
  end

  def self.get(id, session_id:, path: nil)
    namespace = Mediaflux::Http::NamespaceDescribeRequest.new(id: id, path: path, session_token: session_id).metadata
    org = Organization.new(namespace[:id], namespace[:name], namespace[:path], namespace[:description])
    org.store = Store.get_by_name(namespace[:store], session_id: session_id)
    org
  end

  def self.create!(name, title, session_id:)
    id = nil

    namespace_fullname = Rails.configuration.mediaflux["api_root_ns"] + "/" + name
    namespace_request = Mediaflux::Http::NamespaceDescribeRequest.new(path: namespace_fullname, session_token: session_id)
    if namespace_request.exists?
      Rails.logger.info "Namespace #{namespace_fullname} already exists"
      id = nil # TODO: get the id
    else
      Rails.logger.info "Created namespace #{namespace_fullname}"
      namespace_request = Mediaflux::Http::NamespaceCreateRequest.new(namespace: namespace_fullname, description: title, store: Store.all(session_id: session_id).first.name, session_token: session_id)
      id = namespace_request.response_body
    end

    id
  end

  def self.list(session_id:)
    root_namespace = Rails.configuration.mediaflux["api_root_ns"]
    list = Mediaflux::Http::NamespaceListRequest.new(session_token: session_id, parent_namespace: root_namespace)
    namespace_list = list.namespaces

    # Horrible hack until we create a rake task to seed the server
    if namespace_list.count == 0
      create_defaults(session_id: session_id)
      list = Mediaflux::Http::NamespaceListRequest.new(session_token: session_id, parent_namespace: root_namespace)
      namespace_list = list.namespaces
    end

    organizations = namespace_list.map { |ns| Organization.get(ns[:id], session_id: session_id) }

    organizations
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

  def self.create_defaults(session_id:)
    create_root_ns(session_id: session_id)
    organizations = []
    organizations << { name: "rc", title: "Research Computing" }
    organizations << { name: "pppl", title: "Princeton Physics Plasma Lab" }
    organizations << { name: "pul", title: "Princeton University Library" }
    organizations.each do |org|
      Organization.create!(org[:name], org[:title], session_id: session_id)
    end
  end
end
