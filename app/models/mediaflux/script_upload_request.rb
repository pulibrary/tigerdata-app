# frozen_string_literal: true
module Mediaflux
  class ScriptUploadRequest < Request
    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param namespace [String] namespace where the script will be saved
    # @param name [String] name of the script
    # @param url [String] URL where the content of the script will be fetched from
    def initialize(session_token:, namespace:, name:, url:)
      super(session_token: session_token)
      @namespace = namespace
      @name = name
      @url = url
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "asset.create"
    end

    # Returns the id of the asset created
    def result
      response_xml.xpath("/response/reply/result/id").text.to_i
    end

    private

      # Mimics asset.create :namespace -create true /system/scripts :name yourscript.tcl :url http://some-url/with/yourscript.tcl
      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.namespace do
              xml.parent.set_attribute("create", true)
              xml.text(@namespace)
            end
            xml.name @name
            xml.url @url
            # According to the documentation we should be able to pass the `xml-content`
            # directly to Mediaflux (instead of fetching it from a URL) but I have not
            # been able to pass the content formatted properly for Mediaflux to accept it.
            #
            # xml.send('xml-content') do
            #   xml.text(@content)
            # end
          end
        end
      end
  end
end
