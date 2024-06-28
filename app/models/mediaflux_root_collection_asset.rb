# frozen_string_literal: true
class MediafluxRootCollectionAsset
  attr_accessor :id, :type, :name, :tag

  def self.create(session_token:, namespace:, name:)
    namespace = namespace || Rails.configuration.mediaflux["api_root_collection_namespace"]   # /td-prod-001
    name = name || Rails.configuration.mediaflux["api_root_collection_name"]                  # tigerdata
    path = Pathname.new(namespace).join(name).to_s

    check_root = Mediaflux::Http::AssetExistRequest.new(session_token:, path: path)
    return if check_root.exists?

    create_request = Mediaflux::Http::CollectionAssetCreateRoot.new(session_token:, namespace:, name:)
    request.id
  end
end
