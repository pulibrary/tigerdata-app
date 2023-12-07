# frozen_string_literal: true
module Mediaflux
  module Http
    class UpdateAssetRequest < Request
      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param id [Int] Mediaflux asset ID of the asset to update
      # @param tigerdata_values [Hash] Values to update in the asset metadata
      # @param xml_namespace [String] XML namespace for the <project> element
      def initialize(session_token:, id:, tigerdata_values:, xml_namespace: nil, xml_namespace_uri: nil)
        super(session_token: session_token)
        @id = id
        @tigerdata_values = tigerdata_values
        @xml_namespace = xml_namespace || self.class.default_xml_namespace
        @xml_namespace_uri = xml_namespace_uri || self.class.default_xml_namespace_uri
      end

      # Specifies the Mediaflux service to use when updating assets
      # @return [String]
      def self.service
        "asset.set"
      end

      private

        # The generated XML mimics what we get when we issue an Aterm command as follows:
        # > asset.set :id 1234
        #     :meta <
        #       :tigerdata:project <
        #         :title "RDSS test project"
        #         :description "The description of the project"
        #         ...the rest of the fields go here..
        #       >
        #     >
        #
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.id @id
              if @tigerdata_values
                xml.meta do
                  doc = xml.doc
                  root = doc.root
                  # Define the namespace only if this is required
                  root.add_namespace_definition(@xml_namespace, @xml_namespace_uri)

                  element_name = @xml_namespace.nil? ? "project" : "#{@xml_namespace}:project"
                  xml.send(element_name) do
                    xml.code @tigerdata_values[:code]
                    xml.title @tigerdata_values[:title]
                    xml.description @tigerdata_values[:description]
                    xml.data_sponsor @tigerdata_values[:data_sponsor]
                    xml.data_manager @tigerdata_values[:data_manager]
                    xml.updated_by @tigerdata_values[:updated_by]
                    xml.updated_on @tigerdata_values[:updated_on]
                    @tigerdata_values[:departments].each do |department|
                      xml.departments department
                    end
                  end
                end
              end
            end
          end
        end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
  end
end
