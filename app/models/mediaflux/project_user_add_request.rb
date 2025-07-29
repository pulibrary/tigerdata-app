# frozen_string_literal: true
module Mediaflux
  class ProjectUserAddRequest < Request
    attr_reader :project, :project_metadata

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param project [Project] project to be created in Mediaflux
    def initialize(session_token:, project:)
      super(session_token: session_token)
      @project = project
      @id = @project.mediaflux_id
      @xml_namespace = self.class.default_xml_namespace
      @xml_namespace_uri = self.class.default_xml_namespace_uri

      @all_data_users = @project.metadata_model.ro_users + @project.metadata_model.rw_users
      @data_users = @all_data_users.join(",")
    end

    # Specifies the Mediaflux service to use when updating assets
    # @return [String]
    def self.service
      "tigerdata.project.user.add"
    end

    # Returns the entire response returned by the project create service.
    # This includes debug information that is useful to troubleshoot issues
    # if the request fails.
    def debug_output
      response_xml.xpath("response/reply/result/result").to_s
    end

    private

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/BlockLength
      #
      # This is what the call would look like from aterm:
      # tigerdata.project.user.add \
      #   :id 1234 \
      #   :data-user "md1908" \
      #
      # OR FOR MULTIPLE USERS:
      # tigerdata.project.user.add \
      #   :id 1234 \
      #  :data-user "md1908,md1909,md1910" \
      #
      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.id @id
            xml.send("data-user") do
              if @data_users.blank?
                xml.text("n/a")
              else
                xml.text(@data_users)
              end
            end
          end
        end
      end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/BlockLength
  end
end
