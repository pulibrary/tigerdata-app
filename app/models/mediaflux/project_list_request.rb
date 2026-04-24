# frozen_string_literal: true
module Mediaflux
  class ProjectListRequest < Request
    attr_reader :aql_query, :action, :size

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param aql_query [String] Optional AQL query string
    # @param action [String] Optional, by default it uses get-name but it could also be get-meta to get all
    #                        the fields for the assets or `get-values` to get a limited list of fields.
    def initialize(session_token:, aql_query: nil, action: "get-meta")
      super(session_token: session_token)
      @aql_query = aql_query
      @action = action
      # For now we hard-code the size to infinity since only Administrators will fetch a large
      # number of projects and they should get them all. At some point in the future we might
      # want to implement pagination for this list but not now..
      @size = "infinity"
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
          project_directory: metadata.xpath("./ProjectDirectory").text
        }
      end
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.where aql_query if aql_query.present?
            xml.action action if action.present?
            xml.size size if size.present?
            # I tried sorting by path and that slowed down the query to unusable
            # We will need to be considerate of performance when sorting the results
            xml.sort do
              xml.key "name"
            end
          end
        end
      end

      def data_users_from_string(users)
        return [] if users.blank?
        users.split(",").compact_blank
      end
  end
end
