# frozen_string_literal: true
module Mediaflux
  # Constructs a request to mediaflux to approve a project
  #
  # @example
  #  project = Project.first
  #  project.save_in_mediaflux(session_id: SystemUser.mediaflux_session)
  #  approve_req = Mediaflux::ProjectApproveRequest.new(session_token: SystemUser.mediaflux_session, project:)
  #  approve_req.resolve
  #
  class ProjectApproveRequest < Request
    attr_reader :project_metadata, :project
    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param project [Project] project to approve
    # @param xml_namespace [String] XML namespace for the <project> element
    def initialize(session_token:, project:, xml_namespace: nil, xml_namespace_uri: nil)
      super(session_token: session_token)
      @project = project
      @project_metadata = project.metadata
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
      # service.execute :service -name "asset.set" \
      # < :id "1574" :meta -action "replace" < :tigerdata:project -xmlns:tigerdata "tigerdata" < \
      #      :ProjectDirectory "/td-demo-001/tigerdataNS/test-05-30-24" :Title "testing approval" :Description "I want to test the approval updates" \
      #      :Status "approved" :DataSponsor "cac9" :DataManager "mjc12" :Department "RDSS" :DataUser -ReadOnly "true" "la15" :DataUser "woongkim" \
      #      :CreatedOn "30-MAY-2024 09:11:09" :CreatedBy "cac9" :ProjectID "10.34770/tbd"
      #      :StorageCapacity < :Size -Requested "500" -Approved "1" "1" :Unit -Requested "GB" -Approved "TB" "TB" > \
      #      :Performance -Requested "Standard" -Approved "Standard" "Standard" :Submission < :RequestedBy "cac9" \
      #      :RequestDateTime "30-MAY-2024 13:11:09" :ApprovedBy "cac9" :ApprovalDateTime "30-MAY-2024 13:12:44" \
      #      :EventlNote < :NoteDateTime "30-MAY-2024 13:12:44" :NoteBy "cac9" :EventType "Quota" :Message "A note"\
      #   > > :ProjectPurpose "Research" :SchemaVersion "0.6.1" > > >
      #
      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.id project.mediaflux_id
            xml.meta do
              xml.parent.set_attribute("action", "replace")
              doc = xml.doc
              root = doc.root
              # Define the namespace only if this is required
              root.add_namespace_definition(@xml_namespace, @xml_namespace_uri)

              element_name = @xml_namespace.nil? ? "project" : "#{@xml_namespace}:project"
              xml.send(element_name) do
                build_project(xml)
              end
            end
          end
        end
      end

      def build_project(xml)
        build_basic_project_meta(xml)
        build_departments(xml, project_metadata[:departments])
        build_read_only_user(xml, project_metadata[:data_user_read_only])
        build_read_write_users(xml, project_metadata[:data_user_read_write])
        xml.CreatedOn self.class.format_date_for_mediaflux(project_metadata[:created_on])
        xml.CreatedBy project_metadata[:created_by]
        xml.ProjectID project_metadata[:project_id]
        build_storage_capacity(xml)
        build_performance(xml)
        build_submission(xml)
        xml.ProjectPurpose project_metadata[:project_purpose]
        xml.SchemaVersion TigerdataSchema::SCHEMA_VERSION
      end

      def build_basic_project_meta(xml)
        xml.ProjectDirectory project_metadata[:project_directory]
        xml.Title project_metadata[:title]
        xml.Description project_metadata[:description] if project_metadata[:description].present?
        xml.Status project_metadata[:status]
        xml.DataSponsor project_metadata[:data_sponsor]
        xml.DataManager project_metadata[:data_manager]
      end

      def build_departments(xml, departments)
        return if departments.blank?

        departments.each do |department|
          xml.Department department
        end
      end

      def build_read_only_user(xml, ro_users)
        return if ro_users.blank?

        ro_users.each do |ro_user|
          xml.DataUser do
            xml.parent.set_attribute("ReadOnly", true)
            xml.text(ro_user)
          end
        end
      end

      def build_read_write_users(xml, rw_users)
        return if rw_users.blank?

        rw_users.each do |rw_user|
          xml.DataUser rw_user
        end
      end

      def build_storage_capacity(xml)
        xml.StorageCapacity do
          xml.Size do
            build_value(xml, project_metadata[:storage_capacity][:size][:requested], project_metadata[:storage_capacity][:size][:approved])
          end
          xml.Unit do
            build_value(xml, project_metadata[:storage_capacity][:unit][:requested], project_metadata[:storage_capacity][:unit][:approved])
          end
        end
      end

      def build_performance(xml)
        xml.Performance do
          build_value(xml, project_metadata[:storage_performance_expectations][:requested], project_metadata[:storage_performance_expectations][:approved])
        end
      end

      def build_value(xml, requested, approved)
        xml.parent.set_attribute("Requested", requested)
        xml.parent.set_attribute("Approved", approved)
        xml.text(approved)
      end

      def build_submission(xml)
        xml.Submission do
          xml.RequestedBy submission_event.event_person
          xml.RequestDateTime self.class.format_date_for_mediaflux(submission_event.created_at.iso8601)
          xml.ApprovedBy approval_event.event_person
          xml.ApprovalDateTime self.class.format_date_for_mediaflux(approval_event.created_at.iso8601)
          build_submission_note(xml)
        end
      end

      def build_submission_note(xml)
        return if approval_event.event_note.blank?

        xml.EventlNote do
          xml.NoteDateTime self.class.format_date_for_mediaflux(approval_event.created_at.iso8601)
          xml.NoteBy approval_event.event_note["note_by"]
          xml.EventType approval_event.event_note["event_type"]
          xml.Message approval_event.event_note["message"]
        end
      end

      def approval_event
        @approval_event ||= project.provenance_events.find_by(event_type: ProvenanceEvent::APPROVAL_EVENT_TYPE)
      end

      def submission_event
        @submission_event ||= project.provenance_events.find_by(event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE)
      end
  end
end
