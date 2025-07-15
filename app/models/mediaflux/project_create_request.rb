# frozen_string_literal: true
module Mediaflux
    # FOLLOW-UP-PR-1572: think this class should be removed now that we are creating projects
    # via ProjectCreateServiceRequest. However we are calling it in ProjectMediaflux.xml_payload
    # (not sure why) so I am not deleting it just yet.
    class ProjectCreateRequest < AssetCreateRequest
      attr_reader :namespace, :project, :collection, :project_metadata

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
        @project_metadata = project.metadata_model
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
              xml.Title project_metadata.title
              if project_metadata.description.blank?
                xml.Description "description not provided"
              else
                xml.Description project_metadata.description
              end
              # xml.Status project_metadata.status
              xml.DataSponsor project_metadata.data_sponsor
              xml.DataManager project_metadata.data_manager
              departments =  project_metadata.departments || []
              departments.each do |department|
                xml.Department department
              end

              ro_users = project_metadata.ro_users || []
              rw_users = project_metadata.rw_users || []
              all_users = ro_users + rw_users
              data_users = all_users.join(",")
              if data_users.blank?
                xml.DataUser "n/a"
              else
                xml.DataUser data_users
              end
            #   created_on = Mediaflux::Time.format_date_for_mediaflux(project_metadata.created_on)
            #   xml.CreatedOn created_on
            #   xml.CreatedBy project_metadata.created_by
              xml.ProjectID project_metadata.project_id
            #   capacity = project_metadata.storage_capacity.with_indifferent_access
            #   xml.StorageCapacity do
            #     xml.Size capacity["size"]["requested"]
            #     xml.Unit capacity["unit"]["requested"]
            #   end
            #   performance = project_metadata.storage_performance_expectations
            #   xml.Performance do
            #     xml.parent.set_attribute("Requested", performance["requested"])
            #     xml.text(performance["requested"])
            #   end
            #   xml.Submission do
            #     xml.RequestedBy project_metadata.created_by
            #     xml.RequestDateTime created_on
            #   end
            #   xml.ProjectPurpose project_metadata.project_purpose
            #   xml.SchemaVersion TigerdataSchema::SCHEMA_VERSION
            end
          end
          # TODO: SHOULD WE CREATE A PROJECT USING REQUESTED VALUES OR APPROVED VALUES?
          allocation = project_metadata.storage_capacity[:size][:requested].to_s << " " << project_metadata.storage_capacity[:unit][:requested]

          xml.quota do
            xml.allocation allocation
            xml.description "Project Quota"
          end
        end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
end
