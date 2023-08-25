# frozen_string_literal: true
class Store
  attr_accessor :id, :type, :name, :tag

  def initialize(id, type, name, tag)
    @id = id
    @type = type
    @name = name
    @tag = tag
  end

  def self.all(session_id:)
    @all ||= begin
      stores_request = Mediaflux::Http::StoreListRequest.new(session_token: session_id)
      data = stores_request.stores
      stores = data.map do |mf_store|
        Store.new(mf_store[:id], mf_store[:type], mf_store[:name], mf_store[:tag])
      end
      stores
    end
  end

  def self.get_by_name(name, session_id:)
    all(session_id: session_id).find { |store| store.name == name }
  end

  def self.default(session_id:)
    all(session_id: session_id).first
  end
end
