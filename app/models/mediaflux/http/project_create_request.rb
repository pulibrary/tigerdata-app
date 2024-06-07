# frozen_string_literal: true
module Mediaflux
  module Http
    class ProjectCreateRequest < AssetCreateRequest
      attr_reader :namespace, :project, :collection

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param namespace [String] Parent namespace for the asset to be created in
      # @param project [Project] project to be created in Mediaflux
      # @param pid [String] Optional Parent collection id (use this or a namespace not both)
      # @param xml_namespace [String] Optional parameter for metadata xml namspace
      # @param xml_namespace_uri [String] Optional parameter for metadata xml namspace url 
      def initialize(session_token:, namespace:, project:,  xml_namespace: nil, xml_namespace_uri: nil, pid: nil)
        super(session_token:, namespace:, name: project.project_directory_short,  xml_namespace:, xml_namespace_uri:,  pid:)
        @project = project
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
            project_xml(xml)
          end
        end

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def project_xml(xml)
          xml.meta do
            root = xml.doc.root
            root.add_namespace_definition(@xml_namespace, @xml_namespace_uri)
      
            xml.send("#{@xml_namespace}:project") do
              xml.ProjectDirectory project.project_directory
              xml.Title project.metadata[:title]
              xml.Description project.metadata[:description] if project.metadata[:description].present?
              xml.Status project.metadata[:status]
              xml.DataSponsor project.metadata[:data_sponsor]
              xml.DataManager project.metadata[:data_manager]
              departments =  project.metadata[:departments] || []
              departments.each do |department|
                xml.Department department
              end
              ro_users = project.metadata[:data_user_read_only] || []
              ro_users.each do |ro_user|
                xml.DataUser do
                  xml.parent.set_attribute("ReadOnly", true)
                  xml.text(ro_user)
                end
              end
              rw_users = project.metadata[:data_user_read_write] || []
              rw_users.each do |rw_user|
                xml.DataUser rw_user
              end
              created_on = MediafluxTime.format_date_for_mediaflux(project.metadata[:created_on])
              xml.CreatedOn created_on
              xml.CreatedBy project.metadata[:created_by]
              xml.ProjectID project.metadata[:project_id]
              capacity = project.metadata[:storage_capacity]
              xml.StorageCapacity do
                xml.Size capacity["size"]["requested"]
                xml.Unit capacity["unit"]["requested"]
              end
              performance = project.metadata[:storage_performance_expectations]
              xml.Performance do
                xml.parent.set_attribute("Requested", performance["requested"])
                xml.text(performance["requested"])
              end
              xml.Submission do
                xml.RequestedBy project.metadata[:created_by]
                xml.RequestDateTime created_on
              end
              xml.ProjectPurpose project.metadata[:project_purpose]
              xml.SchemaVersion TigerdataSchema::SCHEMA_VERSION
            end
          end
        end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
  end
end
