# frozen_string_literal: true
module Mediaflux
  class RootCollectionAsset
    attr_reader :error

    def initialize(session_token:, root_ns:, parent_collection:)
      @session_token = session_token
      @root_ns = root_ns || Rails.configuration.mediaflux["api_root_collection_namespace"]                  # /princeton or /td-demo-001
      @parent_collection = parent_collection || Rails.configuration.mediaflux["api_root_collection_name"]   # tigerdata
      @parent_ns = Rails.configuration.mediaflux["api_root_ns"]                                             # /td-demo-001/tigerdataNS
      @path = Pathname.new(@root_ns).join(@parent_collection).to_s
      @error = nil
    end

    # Creates the root collection asset (e.g. `tigerdata`)
    # Notice that this collection asset lives under a root namespace (e.g. `/princeton` in production or `td-demo-001` in development)
    def create
      check_root = Mediaflux::AssetExistRequest.new(session_token: @session_token, path: @path)
      return true if check_root.exist?

      if create_root_namespace
        create_request = Mediaflux::CollectionAssetCreateRootRequest.new(session_token: @session_token, namespace: @root_ns, name: @parent_collection)
        create_request.resolve
        @error = create_request.response_error
        return false if @error.present?
        create_parent_ns
      else
        false
      end
    end

    private

      def create_root_namespace
        check_root_namespace = Mediaflux::NamespaceExistRequest.new(session_token: @session_token, namespace: @root_ns)
        return true if check_root_namespace.exist?

        create_namespace_request = Mediaflux::NamespaceCreateRequest.new(session_token: @session_token, namespace: @root_ns)
        create_namespace_request.resolve
        @error = create_namespace_request.response_error
        @error.blank?
      end

      def create_parent_ns
        check_namespace = Mediaflux::NamespaceExistRequest.new(session_token: @session_token, namespace: @parent_ns)
        return true if check_namespace.exist?

        create_namespace_request = Mediaflux::NamespaceCreateRequest.new(session_token: @session_token, namespace: @parent_ns)
        create_namespace_request.resolve
        @error = create_namespace_request.response_error
        @error.blank?
      end
  end
end
