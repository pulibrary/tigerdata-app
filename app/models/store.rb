# frozen_string_literal: true
class Store
  attr_accessor :id, :type, :name, :tag

  def initialize(id, type, name, tag)
    @id = id
    @type = type
    @name = name
    @tag = tag
  end

  def self.all
    # TODO: we should memoize this value
    media_flux = MediaFluxClient.default_instance
    data = media_flux.store_list
    stores = data.map do |mf_store|
      Store.new(mf_store[:id], mf_store[:type], mf_store[:name], mf_store[:tag])
    end
    media_flux.logout
    stores
  end

  def self.get_by_name(name)
    self.all.find {|store| store.name == name }
  end
end
