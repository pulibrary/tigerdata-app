# frozen_string_literal: true
module Mediaflux
  module Http
    class CreateAssetRequest < Request
      attr_reader :namespace, :asset_name, :collection

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param name [String] Name of the Asset
      # @param collection [Boolean] create a collection asset if true
      # @param namespace [String] Optional Parent namespace for the asset to be created in
      def initialize(session_token:, namespace: nil, name:, collection: true, tigerdata_values: nil)
        super(session_token: session_token)
        @namespace = namespace
        @asset_name = name
        @collection = collection
        @tigerdata_values = tigerdata_values
      end

      # Specifies the Mediaflux service to use when creating assets
      # @return [String]
      def self.service
        "asset.create"
      end

      def id
        @id ||= response_xml.xpath("/response/reply/result/id").text
        @id
      end

      private

        # The generated XML mimics what we get when we issue an Aterm command as follows:
        # > asset.set :id path=/sandbox_ns/rdss_collection
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
              xml.name asset_name
              xml.namespace namespace if namespace.present?
              if @tigerdata_values
                xml.meta do
                  # TODO: The parameters to xml.send() need to be adjusted as indicated on
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
                    @tigerdata_values[:data_user_read_only].each do |ro_user|
                      xml.data_users_ro ro_user
                    end
                    @tigerdata_values[:data_user_read_write].each do |rw_user|
                      xml.data_users_rw rw_user
                    end
                    xml.created_on @tigerdata_values[:created_on]
                    xml.created_by @tigerdata_values[:created_by]
                  end
                end
              end
              if collection
                xml.collection do
                  xml.parent.set_attribute("cascade-contained-asset-index", true)
                  xml.parent.set_attribute("contained-asset-index", true)
                  xml.parent.set_attribute("unique-name-index", true)
                  xml.text(collection)
                end
                xml.type "application/arc-asset-collection"
              end
            end
          end
        end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
  end
end
