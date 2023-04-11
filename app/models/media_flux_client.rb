# frozen_string_literal: true
require "net/http"
require "nokogiri"

# A very simple client to interface with a MediaFlux server.
# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
class MediaFluxClient
  attr_reader :session_id

  def self.default_instance
    new
  end

  def initialize(session_id = nil)
    @session_id = session_id
    @session_id ||= connect
  end

  # Fetches MediaFlux's server version information (in XML)
  def version
    version_request = Mediaflux::Http::VersionRequest.new(session_token: @session_id)
    version_request.version
  end

  # Terminates the current session
  def logout
    logout_request = Mediaflux::Http::LogoutRequest.new(session_token: @session_id)
    logout_request.response_body
  end

  # Queries for assets on the given namespace
  def query(aql_where, idx: 1, size: 10)
    query_request = Mediaflux::Http::QueryRequest.new(session_token: @session_id, aql_query: aql_where, size: size, idx: idx)
    query_request.result
  end

  def collection_query(collection_id, idx: 1, size: 10)
    query_request = Mediaflux::Http::QueryRequest.new(session_token: @session_id, collection: collection_id, size: size, idx: idx, action: "get-name")
    query_request.result
  end

  # Fetches metadata for the given asset it
  def get_metadata(id)
    get_request = Mediaflux::Http::GetMetadataRequest.new(session_token: @session_id, id: id)
    get_request.metadata
  end

  def set_note(id, mf_note)
    set_request = Mediaflux::Http::SetNoteRequest.new(session_token: @session_id, id: id, note: mf_note)
    set_request.response_body
  end

  # Creates an empty file (no content) with the name provided
  def create(namespace, _filename)
    create_request = Mediaflux::Http::CreateAssetRequest.new(session_token: @session_id, namespace: namespace, name: nam, collection: false)
    create_request.response_body
  end

  # Creates a collection asset inside a namespace
  def create_collection_asset(namespace, name, _description)
    create_request = Mediaflux::Http::CreateAssetRequest.new(session_token: @session_id, namespace: namespace, name: name)
    xml = create_request.response_xml
    id = xml.xpath("//response/reply/result").text.to_i
    id
  end

  def add_new_files_to_collection(collection_id, count, pattern)
    test_create_request = Mediaflux::Http::TestAssetCreateRequest.new(session_token: @session_id, parent_id: collection_id, count: count, pattern: pattern)
    xml = test_create_request.response_xml
    error = response_error(xml)
    return false if error
    true
  end

  def namespace_exists?(namespace)
    namespace_request = Mediaflux::Http::NamespaceDescribeRequest.new(path: namespace, session_token: @session_id)
    namespace_request.exist?
  end

  def namespace_create(namespace, description, store_name)
    namespace_request = Mediaflux::Http::NamespaceCreateRequest.new(namespace: namespace, description: description, store: store_name, session_token: @session_id)
    namespace_request.response_body
  end

  def namespace_list(parent_namespace)
    namespace_request = Mediaflux::Http::NamespaceListRequest.new(session_token: @session_id, parent_namespace: parent_namespace)
    namespace_request.namespaces
  end

  def namespace_describe(id)
    namespace_request = Mediaflux::Http::NamespaceDescribeRequest.new(id: id, session_token: @session_id)
    namespace_request.metadata
  end

  def namespace_describe_by_name(name)
    namespace_request = Mediaflux::Http::NamespaceDescribeRequest.new(path: name, session_token: @session_id)
    namespace_request.metadata
  end

  def namespace_collection_assets(namespace)
    query_request = Mediaflux::Http::QueryRequest.new(session_token: @session_id, namespace: namespace,
                                                      aql_query: "asset is collection", action: "get-meta")
    xml = query_request.response_xml
    collection_assets = []
    xml.xpath("/response/reply/result/asset").each do |node|
      collection_asset = {
        id: node.xpath("./@id").text,
        path: node.xpath("./path").text,
        name: node.xpath("./name").text,
        description: node.xpath("./description").text
      }
      collection_assets << collection_asset
    end
    collection_assets
  end

  def store_list
    stores_request = Mediaflux::Http::StoreListRequest.new(session_token: @session_id)
    stores_request.stores
  end

  # Creates an empty file (no content) with the name provided in the collection indicated
  def create_in_collection(collection, filename)
    create_request = Mediaflux::Http::CreateAssetRequest.new(session_token: @session_id, parent_id: collection, name: filename, collection: false)
    create_request.response_body
  end

  private

    def response_error(xml)
      return nil if xml.xpath("/response/reply/error").count == 0
      error = {
        title: xml.xpath("/response/reply/error").text,
        message: xml.xpath("/response/reply/message").text
      }
      Rails.logger.error "MediaFlux error: #{error[:title]}, #{error[:message]}"
      error
    end

    def connect
      Mediaflux::Session.new(use_ssl: true).logon
    end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ClassLength
