# frozen_string_literal: true
module Mediaflux
  class ScriptMakeExecutableRequest < Request
    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param path [String] full path to the script to mark as executable
    def initialize(session_token:, path:, session_user: nil)
      super(session_token: session_token, session_user: session_user)
      @path = path
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "asset.set.executable"
    end

    private

      # Mimics asset.set.executable :id path=/system/scripts/fileList.tcl :executable true
      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.id "path=#{@path}"
            xml.executable true
          end
        end
      end
  end
end
