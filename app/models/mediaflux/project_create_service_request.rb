# frozen_string_literal: true
module Mediaflux
  class ProjectCreateServiceRequest < Request
    attr_reader :token, :service_name, :document

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param token         [String] Optional User token for the person executing the command
    #
    def initialize(session_token:, data_manager:, data_sponsor:, title:, description:, directory:, project_id:, department:, quota:, store:, token: nil)
      super(session_token: session_token)
      @token = token
      @data_manager = data_manager
      @data_sponsor = data_sponsor
      @title = title
      @description = description
      @directory = directory
      @project_id = project_id
      @department = department
      @quota = quota
      @store = store
    end

    # Specifies the Mediaflux service to use when creating project
    # @return [String]
    def self.service
      "tigerdata.project.create"
    end

    private

      # rubocop:disable Metrics/MethodLength
      #
      # This is what the call would look like from aterm:
      # tigerdata.project.create \
      #   :data-manager md1908 \
      #   :data-sponsor hc8719 \
      #   :department "Physics" \
      #   :description "Our fake project" \
      #   :directory tigerdata/RC/td-testing/md1908/HectorProject2 \
      #   :project-id "fake.id" \
      #   :quota "10 TB" \
      #   :store db \
      #   :title "Fake Study"
      #
      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.send("data-manager") do
              xml.text(@data_manager)
            end
            xml.send("data-sponsor") do
              xml.text(@data_sponsor)
            end
            xml.department @department
            xml.description @description
            xml.directory @directory
            xml.send("project-id") do
              xml.text(@project_id)
            end
            xml.quota @quota
            xml.store @store
            xml.title @title
          end
        end
      end
    # rubocop:enable Metrics/MethodLength
  end
end
