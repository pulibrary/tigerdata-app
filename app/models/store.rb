# frozen_string_literal: true

# Represents a Mediaflux store with id, type, name, and tag.
class Store
  attr_accessor :id, :type, :name, :tag

  # Initializes a new Store instance.
  # @param id [String] the store id.
  # @param type [String] the store type.
  # @param name [String] the store name.
  # @param tag [String] the store tag.
  def initialize(id, type, name, tag)
    @id = id
    @type = type
    @name = name
    @tag = tag
  end

  # Gets all stores from Mediaflux.
  # @param session_id [String] the Mediaflux session id.
  # @return [Array<Store>] the list of stores.
  def self.all(session_id:)
    @all ||= begin
      stores_request = Mediaflux::StoreListRequest.new(session_token: session_id)
      data = stores_request.stores
      stores = data.map do |mf_store|
        Store.new(mf_store[:id], mf_store[:type], mf_store[:name], mf_store[:tag])
      end
      stores
    end
  end

  # Gets a store by name.
  # @param name [String] the store name.
  # @param session_id [String] the Mediaflux session id.
  # @return [Store, nil] the store or nil if not found.
  def self.get_by_name(name, session_id:)
    all(session_id: session_id).find { |store| store.name == name }
  end

  # Gets the default store.
  # @param session_id [String] the Mediaflux session id.
  # @return [Store] the default store.
  def self.default(session_id:)
    all(session_id: session_id).first
  end
end
