# frozen_string_literal: true
module Mediaflux
  class ScriptFileListInitRequest < Request
    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param path [String] path to the collection we want the list of files for
    def initialize(session_token:, path:, session_user: nil)
      super(session_token: session_token, session_user: session_user)
      @path = path
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "asset.script.execute"
    end

    # Returns the iterator that would be use to fetch the file list
    def result
      # Weird: the result comes as an XML inside the typical /response/reply/result
      nested_response = response_xml.xpath("/response/reply/result").text
      nested_xml = Nokogiri::XML.parse(nested_response)
      nested_xml.xpath("/result/iterator").text.to_i
    end

    private

      # NOTE: This code is hard-coded to a very specific TCL script that must have been
      # installed in Mediaflux ahead of time.
      #
      # We could make the script name configurable but the complication is that
      # different scripts will have different parameters and return entirely different
      # kind of results.
      #
      # TODO: document the steps to install the script.
      # (for now see ./app/lib/fileList.tcl)
      def build_http_request_body(name:)
        super do |xml|
          # asset.script.execute :id path="/system/scripts/fileList.tcl" :arg -name path "/path/to/collection"
          xml.args do
            xml.id "path=/system/scripts/fileList.tcl"
            xml.arg name: "path" do
              xml.text(@path)
            end
          end
        end
      end
  end
end
