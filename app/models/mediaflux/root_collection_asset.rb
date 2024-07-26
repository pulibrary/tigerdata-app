# frozen_string_literal: true
module Mediaflux
  class RootCollectionAsset
    attr_reader :error, :root_ns, :parent_collection, :parent_ns, :path

    # In the context of this class:
    #
    # root_ns:            The root namespace (e.g. /princeton) for everything in Mediaflux.
    #
    # parent_collection:  The collection that is the parent to all other collections (e.g. tigerdata)
    #                     and this collection lives under root_ns (e.g. /princeton/tigerdata)
    #
    # parent_ns:          The namespace that is the parent to all namespaces for projects and
    #                     and this namespace lives under root_ns  (e.g. /princeton/tigerdataNS)
    #
    # Notice that parent_ns is a sibling to parent_collection (i.e. they both live under root_ns)
    #
    # During development the root_ns is typicall "/td-demo-001" and parent_collection and parent_ns
    # live under it (e.g. /td-demo-001/tigerdata and /td-demo-001/tigerdataNS).
    #
    # When running the test suite root_ns is typically "/td-test-001/test" and the parent_collection
    # and parent_ns live under it (e.g. /td-test-001/test/tigerdata and /td-test-001/test/tigerdataNS).
    #
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
