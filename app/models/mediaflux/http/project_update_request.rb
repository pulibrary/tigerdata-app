# frozen_string_literal: true
module Mediaflux
  module Http
    class ProjectUpdateRequest < Request
      attr_reader :project, :project_metadata

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param project [Project] project to be created in Mediaflux
      def initialize(session_token:, project:)
        super(session_token: session_token)
        @project = project
        @id = @project.mediaflux_id
        @xml_namespace = self.class.default_xml_namespace
        @xml_namespace_uri = self.class.default_xml_namespace_uri
        @project_metadata = ProjectMetadata.new(project: project)
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
        # rubocop:disable Metrics/BlockLength
        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.id @id
              xml.meta do
                doc = xml.doc
                root = doc.root
                root.add_namespace_definition(@xml_namespace, @xml_namespace_uri)

                element_name = "#{@xml_namespace}:project"
                xml.send(element_name) do
                  xml.ProjectDirectory project.project_directory
                  xml.Title project_metadata.title
                  xml.Description project_metadata.description if project_metadata.description.present?
                  xml.Status project_metadata.status
                  xml.SchemaVersion TigerdataSchema::SCHEMA_VERSION
                  xml.DataSponsor project_metadata.data_sponsor
                  xml.DataManager project_metadata.data_manager
                  departments = project_metadata.departments || []
                  departments.each do |department|
                    xml.Department department
                  end
                  xml.CreatedBy project_metadata.created_by
                  ro_users = project_metadata.ro_users || []
                  ro_users.each do |ro_user|
                    xml.DataUser do
                      xml.parent.set_attribute("ReadOnly", true)
                      xml.text(ro_user)
                    end
                  end
                  rw_users = project_metadata.rw_users || []
                  rw_users.each do |rw_user|
                    xml.DataUser rw_user
                  end
                  created_on = Mediaflux::Time.format_date_for_mediaflux(project_metadata.created_on)
                  xml.CreatedOn created_on
                  xml.UpdatedBy project_metadata.updated_by
                  updated_on = Mediaflux::Time.format_date_for_mediaflux(project_metadata.updated_on)
                  xml.UpdatedOn updated_on
                  xml.ProjectID project_metadata.project_id
                  capacity = project_metadata.storage_capacity
                  xml.StorageCapacity do
                    xml.Size capacity["size"]["requested"]
                    xml.Unit capacity["unit"]["requested"]
                  end
                  performance = project_metadata.storage_performance_expectations
                  xml.Performance do
                    xml.parent.set_attribute("Requested", performance["requested"])
                    xml.text(performance["requested"])
                  end
                  xml.Submission do
                    xml.RequestedBy project_metadata.created_by
                    xml.RequestDateTime created_on
                  end
                  xml.ProjectPurpose project_metadata.project_purpose
                end
              end
            end
          end
        end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/BlockLength
    end
  end
end
