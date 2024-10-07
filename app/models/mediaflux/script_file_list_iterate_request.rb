# frozen_string_literal: true
module Mediaflux
  class ScriptFileListIterateRequest < Request
    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param iterator [Int] the iterator returned by ScriptFileListInitRequest
    def initialize(session_token:, iterator:, session_user: nil)
      super(session_token: session_token, session_user: session_user)
      @iterator = iterator
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "asset.script.execute"
    end

    # Have we iterated over all the data?
    def complete?
      nested_response = response_xml.xpath("/response/reply/result").text
      nested_xml = Nokogiri::XML.parse(nested_response)
      nested_xml.xpath("/result/iterated/@complete").first.text == "true"
    end

    # Returns the file list
    def result
      nested_response = response_xml.xpath("/response/reply/result").text
      nested_xml = Nokogiri::XML.parse(nested_response)
      nested_xml.xpath("/result/name").map do |file|
        { id: file["id"], name: file.text }
      end
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          # asset.script.execute :id path="/system/scripts/fileList.tcl" :arg -name iterator 123
          xml.args do
            xml.id "path=/system/scripts/fileList.tcl"
            xml.arg name: "iterator" do
              xml.text(@iterator)
            end
          end
        end
      end
  end
end
