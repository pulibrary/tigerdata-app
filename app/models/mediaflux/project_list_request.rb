# frozen_string_literal: true
module Mediaflux
  class ProjectListRequest < Request
    attr_reader :aql_query, :collection, :action, :deep_search, :iterator

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param aql_query [String] Optional AQL query string
    # @param collection [Integer] Optional collection id
    # @param action [String] Optional, by default it uses get-name but it could also be get-meta to get all
    #                        the fields for the assets or `get-values` to get a limited list of fields.
    # @param deep_search [Bool] Optional, false by default. When true queries the collection and it subcollections.
    # @param iterator [Bool] Optional, true by default. When true returns an iterator.  When false returns a list of results
    def initialize(session_token:, aql_query: nil, action: "get-meta", deep_search: true)
      super(session_token: session_token)
      @aql_query = aql_query
      @collection = collection
      @action = action
      @deep_search = deep_search
    end

    # Specifies the Mediaflux service to use when running a query
    # @return [String]
    def self.service
      "asset.query"
    end

    # Returns the iterator that could be used to fetch the data
    def results
      xml = response_xml
      assets = xml.xpath("/response/reply/result/asset")
      assets.map do |asset|
        metadata = asset.xpath("./meta//tigerdata:project", "tigerdata" => "tigerdata")
        {
          mediaflux_id: asset.xpath("@id").first.value,
          title: metadata.xpath("./Title").text,
          description: metadata.xpath("./Description").text,
          project_purpose: metadata.xpath("./ProjectPurpose").text,
          data_sponsor: metadata.xpath("./DataSponsor").text,
          data_manager: metadata.xpath("./DataManager").text,
          data_users: data_users_from_string(metadata.xpath("./DataUser").text),
          directory: metadata.xpath("./ProjectDirectory").text
        }
      end
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.where aql_query if aql_query.present?
            xml.action action if action.present?
          end
        end
      end

      def data_users_from_string(users)
        return [] if users.blank?
        users.split(",")
      end
  end
end
