# frozen_string_literal: true
module Mediaflux
  class RootCollectionAsset
    attr_reader :error

    def initialize(session_token:, namespace:, name:)
      @session_token = session_token
      @namespace = namespace || Rails.configuration.mediaflux["api_root_collection_namespace"]   # /td-prod-001
      @name = name || Rails.configuration.mediaflux["api_root_collection_name"]                  # tigerdata
      @path = Pathname.new(namespace).join(name).to_s
      @error = nil
    end

    def create
      check_root = Mediaflux::Http::AssetExistRequest.new(session_token: @session_token, path: @path)
      return true if check_root.exist?

      if create_root_namespace
        create_request = Mediaflux::Http::CollectionAssetCreateRootRequest.new(session_token: @session_token, namespace: @namespace, name: @name)
        create_request.resolve
        @error = create_request.response_error
        create_request.id.present?
      else
        false
      end
    end

    private

      def create_root_namespace
        check_root_namespace = Mediaflux::Http::NamespaceExistRequest.new(session_token: @session_token, path: @namespace)
        return true if check_root_namespace.exist?

        create_namespace_request = Mediaflux::Http::NamespaceCreateRequest.new(session_token: @session_token, namespace: @namespace)
        create_namespace_request.resolve
        @error = create_namespace_request.response_error
        if @error.present?
          false
        else
          true
        end
      end
  end
end
