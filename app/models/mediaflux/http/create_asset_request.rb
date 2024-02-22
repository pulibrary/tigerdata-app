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
      # @param pid [String] Optional Parent collection id (use this or a namespace not both)
      # @param tigerdata_values [Hash] Optional parameter for the tigerdata metdata to be applied to the new asset in the meta field
      # @param xml_namespace [String]
      def initialize(session_token:, namespace: nil, name:, collection: true, tigerdata_values: nil, xml_namespace: nil, xml_namespace_uri: nil, pid: nil)
        super(session_token: session_token)
        @namespace = namespace
        @asset_name = name
        @collection = collection
        @tigerdata_values = tigerdata_values
        @xml_namespace = xml_namespace || self.class.default_xml_namespace
        @xml_namespace_uri = xml_namespace_uri || self.class.default_xml_namespace_uri
        @pid = pid
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
        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.name asset_name
              xml.namespace namespace if namespace.present?
              tigerdata_values_xml(xml)
              collection_xml(xml)
              if @pid.present?
                xml.pid @pid
              end
            end
          end
        end

        def collection_xml(xml)
          return unless collection
          xml.collection do
            xml.parent.set_attribute("cascade-contained-asset-index", true)
            xml.parent.set_attribute("contained-asset-index", true)
            xml.parent.set_attribute("unique-name-index", true)
            xml.text(collection)
          end
          xml.type "application/arc-asset-collection"
        end

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def tigerdata_values_xml(xml)
          return unless @tigerdata_values
          xml.meta do
            doc = xml.doc
            root = doc.root
            # Define the namespace only if this is required
            root.add_namespace_definition(@xml_namespace, @xml_namespace_uri)

            element_name = @xml_namespace.nil? ? "project" : "#{@xml_namespace}:project"
            xml.send(element_name) do
              xml.Code @tigerdata_values[:code]
              xml.Title @tigerdata_values[:title]
              xml.Description @tigerdata_values[:description] if @tigerdata_values[:description].present?
              xml.Status @tigerdata_values[:status]
              xml.DataSponsor @tigerdata_values[:data_sponsor]
              xml.DataManager @tigerdata_values[:data_manager]
              departments = @tigerdata_values[:departments] || []
              departments.each do |department|
                xml.Department department
              end
              ro_users = @tigerdata_values[:data_user_read_only] || []
              ro_users.each do |ro_user|
                xml.DataUser do
                  xml.parent.set_attribute("ReadOnly", true)
                  xml.text(ro_user)
                end
              end
              rw_users = @tigerdata_values[:data_user_read_write] || []
              rw_users.each do |rw_user|
                xml.DataUser rw_user
              end
              xml.CreatedOn @tigerdata_values[:created_on]
              xml.CreatedBy @tigerdata_values[:created_by]
              xml.ProjectID @tigerdata_values[:project_id]
              xml.StorageCapacity @tigerdata_values[:storage_capacity]
              xml.StoragePerformance @tigerdata_values[:storage_performance]
              xml.ProjectPurpose @tigerdata_values[:project_purpose]
            end
          end
        end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
  end
end
