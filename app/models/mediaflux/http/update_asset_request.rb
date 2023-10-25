# frozen_string_literal: true
module Mediaflux
  module Http
    class UpdateAssetRequest < Request
      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param id [Int] Mediaflux asset ID of the asset to update
      # @param tigerdata_values [Hash] Values to update in the asset metadata
      def initialize(session_token:, id:, tigerdata_values:)
        super(session_token: session_token)
        @id = id
        @tigerdata_values = tigerdata_values
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
                  # TODO:
                  # The parameters to xml.send() need to be adjusted as indicated on
                  # GitHub issue https://github.com/pulibrary/tiger-data-app/issues/227
                  #
                  # The values we are passing right here produce the correct XML
                  # structure but the wrong xmlns value, which we manually adjust
                  # in request.rb
                  #
                  # See also https://nokogiri.org/rdoc/Nokogiri/XML/Builder.html
                  xml.send("tigerdata:project", "xmlns" => "tigerdata:project") do
                    xml.code @tigerdata_values[:code]
                    xml.title @tigerdata_values[:title]
                    xml.description @tigerdata_values[:description]
                    xml.data_sponsor @tigerdata_values[:data_sponsor]
                    xml.data_manager @tigerdata_values[:data_manager]
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
