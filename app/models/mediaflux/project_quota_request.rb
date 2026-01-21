# frozen_string_literal: true
module Mediaflux
  class ProjectQuotaRequest < Request
    attr_reader :token, :service_name, :document

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param asset_id      [Int] The Mediaflux asset ID for the project
    def initialize(session_token:, asset_id:)
      super(session_token: session_token)
      @asset_id = asset_id
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "tigerdata.project.quota.get"
    end

    # Returns the entire response returned by the service.
    def debug_output
      response_xml.xpath("response/reply/result/result").to_s
    end

    # Returns the id of the collection created in Mediaflux
    def quota
      result = response_xml.xpath("response/reply/result")
      {
        quota_allocation: result.xpath("quota-allocation").text.to_i,
        quota_allocation_human: result.xpath("quota-allocation/@h").text,
        quota_used: result.xpath("quota-used").text.to_i,
        quota_used_human: result.xpath("quota-used/@h").text,
        project_files: result.xpath("project-files").text.to_i,
        project_files_human: result.xpath("project-files/@h").text,
        recycle_bin: result.xpath("recycle-bin").text.to_i,
        recycle_bin_human: result.xpath("recycle-bin/@h").text,
        old_versions: result.xpath("old-versions").text.to_i,
        old_versions_human: result.xpath("old-versions/@h").text
      }
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.id @asset_id
          end
        end
      end
  end
end
