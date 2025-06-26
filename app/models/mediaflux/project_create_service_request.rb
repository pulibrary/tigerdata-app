# frozen_string_literal: true
module Mediaflux
  class ProjectCreateServiceRequest < Request
    attr_reader :token, :service_name, :document

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param service_name  [String] Name of the service to run.
    #                               Can be any command like asset.namespace.list
    # @param token         [String] Optional User token for the person executing the command
    # @param document      [String] Optional xml document to pass on to the service.
    #                               Used to pass parameters to the command
    #
    # asset.script.execute :id path=/system/scripts/projectCreate.tcl
    #   :arg -name doi 10.123/456
    #   :arg -name directory test-308
    #   :arg -name title "hello world"
    #
    # => :result -id "2212" "<result><id>2213</id></result>"
    #
    def initialize(session_token:, doi:, directory:, title:, token: nil)
      super(session_token: session_token)
      @doi = doi
      @directory = directory
      @title = title
      @token = token
    end

    # Specifies the Mediaflux service to use when creating project
    # @return [String]
    def self.service
      "asset.script.execute"
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.id "path=/system/scripts/projectCreate.tcl"
            xml.arg name: "doi" do
              xml.text(@doi)
            end
            xml.arg name: "directory" do
              xml.text(@directory)
            end
            xml.arg name: "title" do
              xml.text(@title)
            end
          end
        end
      end
  end
end
