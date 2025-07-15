# frozen_string_literal: true
module Mediaflux
  class ProjectCreateServiceRequest < Request
    attr_reader :token, :service_name, :document

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param token         [String] Optional User token for the person executing the command
    # @param project       [Project] A project object
    def initialize(session_token:, project:, token: nil)
      super(session_token: session_token)
      @token = token
      @project = project
      @data_manager = @project.metadata_model.data_manager
      @data_sponsor = @project.metadata_model.data_sponsor
      @title = @project.metadata_model.title
      @description = @project.metadata_model.description
      @directory = @project.metadata_model.project_directory
      @project_id = @project.metadata_model.project_id
      # We pass only the first department for now
      # See https://github.com/PrincetonUniversityLibrary/tigerdata-config/issues/193
      @department = @project.metadata_model.departments.first
      @quota = "#{@project.metadata_model.storage_capacity['size']['approved']} #{@project.metadata_model.storage_capacity['unit']['approved']}"
      # We currently don't have this value
      # See https://github.com/pulibrary/tigerdata-app/issues/1609
      @store = "db"
    end

    # Specifies the Mediaflux service to use when creating project
    # @return [String]
    def self.service
      "tigerdata.project.create"
    end

    # Returns the entire response returned by the project create service.
    # This includes debug information that is useful to troubleshoot issues
    # if the request fails.
    def debug_output
      response_xml.xpath("response/reply/result/result").to_s
    end

    # Returns the id of the collection created in Mediaflux
    def mediaflux_id
      # Extract the <id>nnnn</id> value from the output and then extract the
      # numeric value inside of it.
      id_xml = debug_output.match("\&lt\;id\&gt\;[0-9]*\&lt\;\/id\&gt\;").to_s
      id_xml.gsub("&lt;id&gt;", "").gsub("&lt;/id&gt;", "").to_i
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
