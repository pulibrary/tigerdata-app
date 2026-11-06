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
      project_metadata = ProjectMetadata.new(@project)
      @data_manager = project_metadata.data_manager
      @data_sponsor = project_metadata.data_sponsor
      @title = project_metadata.title
      @description = project_metadata.description
      @directory = project_metadata.project_directory
      @project_id = project_metadata.project_id
      @department = departments_string(project_metadata.departments)
      @quota = "#{project_metadata.storage_capacity['size']['approved']} #{project_metadata.storage_capacity['unit']['approved']}"
      @number_of_files = project_metadata.number_of_files
      @hpc = project_metadata.hpc
      @smb = project_metadata.smb_request
      @globus = project_metadata.globus_request
      @project_purpose = project_metadata.project_purpose
      @data_security_level = require_data_security_level(project_metadata.data_security_level)
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
      if new_project_create?
        response_xml.xpath("response/reply/result/lineage").to_s
      else
        response_xml.xpath("response/reply/result/result").to_s
      end
    end

    # Returns the id of the collection created in Mediaflux
    def mediaflux_id
      if new_project_create?
        # We have the value in the `id` node
        response_xml.xpath("response/reply/result/id").text.to_i
      else
        # Extract the <id>nnnn</id> value from the output and then extract the
        # numeric value inside of it.
        decoded_string = CGI.unescapeHTML(debug_output)
        xml_doc = Nokogiri::XML(decoded_string)
        (xml_doc.xpath("result/result/id/text()").to_s).to_i
      end
    end

    private

    # rubocop:disable Metrics/MethodLength
    #
    # This is what the call would look like from aterm:
    # tigerdata.project.create \
    #   :data-manager md1908 \
    #   :data-sponsor jh6441 \
    #   :department "Physics" \
    #   :description "Our fake project" \
    #   :directory tigerdata/RC/td-testing/md1908/JaymeeProject2 \
    #   :project-id "fake.id" \
    #   :quota "10 TB" \
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
          xml.title @title
          xml.send("number-of-files") do
            xml.text(@number_of_files)
          end
          xml.hpc @hpc
          xml.smb @smb
          xml.globus @globus
          if @project_purpose.present?
            xml.send("project-purpose") do
              xml.text(@project_purpose)
            end
          end
          # Integer 0 is Public. Do not use present? — 0.present? is false and would omit the value.
          xml.send("security-level") do
            xml.text(@data_security_level.to_s)
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # tigerdata.project.create requires security-level. There is no system default.
    # @param level [Integer, String, nil]
    # @return [Integer]
    def require_data_security_level(level)
      normalized = Integer(level) unless level.nil?
      return normalized if [0, 1, 2, 3].include?(normalized)

      raise ArgumentError, "tigerdata.project.create requires security-level to be one of 0, 1, 2, 3"
    end

    # Returns the names of the departments as a comma separated string
    def departments_string(departments)
      names = departments.map { |code| Affiliation.where(code:).first&.name || code }
      names.compact.join(", ")
    end

    # This is method is only needed while we are transitioning to the new Java based
    # `tigerdata.project.create` service. We can remove this method once the new
    # service has been rolled out to all our environments.
    #
    # See https://github.com/pulibrary/tigerdata-app/issues/2402 for details.
    #
    def new_project_create?
      response_xml.xpath("response/reply/result/id").count > 0
    end
  end
end
