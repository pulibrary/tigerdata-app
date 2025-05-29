# frozen_string_literal: true
require "rails_helper"

describe ProjectXmlPresenter, type: :model, connect_to_mediaflux: false do
  subject(:presenter) { described_class.new(project) }

  let(:data_sponsor) { FactoryBot.create(:project_sponsor, uid: "abc123") }
  let(:data_manager) { FactoryBot.create(:data_manager, uid: "bcd234") }
  let(:read_only) { FactoryBot.create :user }
  let(:read_write) { FactoryBot.create :user }
  let(:department) { "77777" }
  let(:submitter) { FactoryBot.create(:user, uid: "cde345") }
  let(:submission) do
    {
      requested_by: submitter.uid,
      request_date_time: Time.current.in_time_zone("America/New_York").iso8601
    }
  end
  let(:status) { ::Project::PENDING_STATUS }
  let(:metadata_model) do
    hash = {
      data_sponsor: data_sponsor.uid,
      data_manager: data_manager.uid,
      project_directory: "/tigerdata/abcd1/test-project-2",
      title: "project 123",
      departments: [department], # RDSS test code in fixture data
      description: "hello world",
      data_user_read_only: [read_only.uid],
      data_user_read_write: [read_write.uid],
      status: status,
      created_on: Time.current.in_time_zone("America/New_York").iso8601,
      created_by: FactoryBot.create(:user).uid,
      project_id: "10.34770/az09-0004"
    }
    ProjectMetadata.new_from_hash(hash)
  end
  let(:project) do
    FactoryBot.create(:project_with_doi,
                      data_sponsor: data_sponsor.uid,
                      data_manager: data_manager.uid,
                      metadata_model: metadata_model)
  end
  let(:submission_event) { FactoryBot.create(:submission_event, project: project, event_person: submitter.uid) }

  let(:schema_file_path) { Rails.root.join("lib", "assets", "tigerdata_metadata", "v0.8", "TigerData_StandardMetadataSchema_v0.8.xsd") }
  let(:schema_file) do
    File.read(schema_file_path).tap do |xsd|
      # Replace the reference to `xml.xsd` from the xsd with a reference to our
      # local copy of the file, otherwise the validation tends to fail because
      # Nokogiri cannot load the original `xml.xsd` file from the W3C
      # source. ¯\_(ツ)_/¯
      # For more information see: https://stackoverflow.com/a/18527198/446681
      local_xml_xsd = Pathname.new("./lib/assets/xml.xsd").realpath.to_s
      xsd.sub!("https://www.w3.org/2001/xml.xsd", "file://#{local_xml_xsd}")
    end
  end
  let(:schema) { Nokogiri::XML::Schema(schema_file) }

  before do
    submission_event
  end

  describe "#document" do
    let(:document) { presenter.document }
    let(:root) { document.root }

    it "generates a XML Document" do
      expect(document).to be_a(Nokogiri::XML::Document)
    end

    it "ensures that the root node is a <resource> element with the required attributes" do
      expect(root).to be_a(Nokogiri::XML::Element)
      expect(root.name).to eq("resource")
      expect(root["resourceClass"]).to eq("Project")
      expect(root["resourceID"]).to eq(project.metadata_model.project_id)
      expect(root["resourceIDType"]).to eq("DOI")
    end

    describe "<projectID>" do
      let(:node) { root.at_xpath("projectID") }

      it "builds a <projectID> element containing the ID of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("projectID")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
        expect(node.content).to eq(project.metadata_model.project_id)
      end
    end

    describe "<dataSponsor>" do
      let(:node) { root.at_xpath("dataSponsor") }

      it "builds a <dataSponsor> element containing the data sponsor of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("dataSponsor")
        expect(node["userID"]).to eq(project.metadata_model.data_sponsor)
        expect(node["discoverable"]).to eq("true")
        expect(node["inherited"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
      end
    end

    describe "<dataManager>" do
      let(:node) { root.at_xpath("dataManager") }

      it "builds a <dataManager> element containing the data manager of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("dataManager")
        expect(node["userID"]).to eq(project.metadata_model.data_manager)
        expect(node["discoverable"]).to eq("true")
        expect(node["inherited"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
      end
    end

    describe "<departments>" do
      let(:node) { root.at_xpath("departments") }

      it "builds a <departments> element containing the departments of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("departments")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
        expect(node.children.length).to eq(presenter.departments.length)
      end

      describe "<department>" do
        let(:node) { root.at_xpath("departments/department") }

        it "builds a <department> element for each department associated with the project" do
          expect(node).to be_a(Nokogiri::XML::Element)
          expect(node.name).to eq("department")
          expect(node["inherited"]).to eq("true")
          expect(node["departmentCode"]).to eq(presenter.departments.first)
          expect(node.content).to eq("0#{department}")
        end
      end
    end

    describe "<projectDirectory>" do
      let(:node) { root.at_xpath("projectDirectory") }

      it "builds a <projectDirectory> element containing the project directory structure information of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("projectDirectory")
        expect(node["approved"]).to eq("false")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("false")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
        expect(node.children.length).to eq(presenter.project_directory.length)
      end

      describe "<projectDirectoryPath>" do
        let(:node) { root.at_xpath("projectDirectory/projectDirectoryPath") }

        it "builds a <projectDirectoryPath> element containing project directory information for a file-system node" do
          expect(node).to be_a(Nokogiri::XML::Element)
          expect(node.name).to eq("projectDirectoryPath")
          expect(node["protocol"]).to eq("NFS")
          expect(node.content).to eq(presenter.project_directory.first)
        end
      end
    end

    describe "<title>" do
      let(:node) { root.at_xpath("title") }

      it "builds a <title> element containing the title of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("title")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
        expect(node.content).to eq(project.metadata_model.title)
      end
    end

    describe "<description>" do
      let(:node) { root.at_xpath("description") }

      it "builds a <description> element containing the description of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("description")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
        expect(node.content).to eq(project.metadata_model.description)
      end
    end

    describe "<projectPurpose>" do
      let(:node) { root.at_xpath("projectPurpose") }

      it "builds a <projectPurpose> element containing the stated purpose for the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("projectPurpose")
        expect(node["inherited"]).to eq("true")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
        expect(node.content).to eq(project.metadata_model.project_purpose)
      end
    end

    describe "<storageCapacity>" do
      let(:node) { root.at_xpath("storageCapacity") }

      it "builds a <storageCapacity> element containing the storage capacity information for the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("storageCapacity")
        expect(node["approved"]).to eq("false")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("false")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
      end
    end

    describe "<storagePerformance>" do
      let(:node) { root.at_xpath("storagePerformance") }

      it "builds a <storagePerformance> element containing the storage performance information for the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("storagePerformance")
        expect(node["approved"]).to eq("false")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("false")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
      end

      describe "<requestedValue>" do
        let(:node) { root.at_xpath("storagePerformance/requestedValue") }

        it "builds a <requestedValue> element containing the storage request information for the project" do
          expect(node).to be_a(Nokogiri::XML::Element)
          expect(node.name).to eq("requestedValue")
          expect(node.content).to eq(presenter.requested_storage)
        end
      end
    end

    describe "<numberOfFiles>" do
      let(:node) { root.at_xpath("numberOfFiles") }

      it "builds a <numberOfFiles> element containing the number of files for the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("numberOfFiles")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("false")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
      end
    end

    describe "<hpc>" do
      let(:node) { root.at_xpath("hpc") }

      it "builds a <hpc> element detailing high performance compute cluster information" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("hpc")
        expect(node["inherited"]).to eq("true")
        expect(node["discoverable"]).to eq("false")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
        expect(node.content).to eq(presenter.hpc)
      end
    end

    describe "<accessPoints>" do
      let(:node) { root.at_xpath("accessPoints") }

      it "builds a <accessPoints> element detailing the SMB and NFS mount points" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("accessPoints")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("false")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
      end

      describe "<smbEnable>" do
        let(:node) { root.at_xpath("accessPoints/smbEnable") }

        it "builds a <smbEnable> element detailing the SMB mount status" do
          expect(node).to be_a(Nokogiri::XML::Element)
          expect(node.name).to eq("smbEnable")
          expect(node["approved"]).to eq(presenter.smb_enable_approved?.to_s)
        end

        describe "<smbEnableSetting>" do
          let(:node) { root.at_xpath("accessPoints/smbEnable/smbEnableSetting") }

          it "builds a <smbEnableSetting> element detailing the SMB mount status" do
            expect(node).to be_a(Nokogiri::XML::Element)
            expect(node.name).to eq("smbEnableSetting")
            expect(node.content).to eq(presenter.smb_enable_approved?.to_s)
          end
        end

        describe "<requestedValue>" do
          let(:node) { root.at_xpath("accessPoints/smbEnable/requestedValue") }

          it "builds a <requestedValue> element detailing whether or not SMB was requested" do
            expect(node).to be_a(Nokogiri::XML::Element)
            expect(node.name).to eq("requestedValue")
            expect(node.content).to eq(presenter.smb_enable_requested?.to_s)
          end
        end

        describe "<approvedValue>" do
          let(:node) { root.at_xpath("accessPoints/smbEnable/approvedValue") }

          it "builds a <approvedValue> element detailing whether or not SMB was approved" do
            expect(node).to be_a(Nokogiri::XML::Element)
            expect(node.name).to eq("approvedValue")
            expect(node.content).to eq(presenter.smb_enable_approved?.to_s)
          end
        end
      end

      describe "<globusEnable>" do
        describe "<globusEnableSetting>" do
        end
        let(:node) { root.at_xpath("accessPoints/globusEnable") }

        it "builds a <globusEnable> element detailing the Globus mount status" do
          expect(node).to be_a(Nokogiri::XML::Element)
          expect(node.name).to eq("globusEnable")
          expect(node["approved"]).to eq(presenter.globus_enable_approved?.to_s)
        end

        describe "<globusEnableSetting>" do
          let(:node) { root.at_xpath("accessPoints/globusEnable/globusEnableSetting") }

          it "builds a <globusEnableSetting> element detailing the Globus mount status" do
            expect(node).to be_a(Nokogiri::XML::Element)
            expect(node.name).to eq("globusEnableSetting")
            expect(node.content).to be_a(String)
            expect(node.content).to eq(presenter.globus_enable_requested)
          end
        end

        describe "<requestedValue>" do
          let(:node) { root.at_xpath("accessPoints/globusEnable/requestedValue") }

          it "builds a <requestedValue> element detailing whether or not Globus was requested" do
            expect(node).to be_a(Nokogiri::XML::Element)
            expect(node.name).to eq("requestedValue")
            expect(node.content).to be_a(String)
            expect(node.content).to eq(presenter.globus_enable_requested)
          end
        end

        describe "<approvedValue>" do
          let(:node) { root.at_xpath("accessPoints/globusEnable/approvedValue") }

          it "builds a <approvedValue> element detailing whether or not Globus was approved" do
            expect(node).to be_a(Nokogiri::XML::Element)
            expect(node.name).to eq("approvedValue")
            expect(node.content).to be_a(String)
            expect(node.content).to eq(presenter.globus_enable_approved)
          end
        end
      end
    end

    describe "<projectPurpose>" do
      let(:node) { root.at_xpath("projectPurpose") }

      it "builds a <projectPurpose> element detailing the purpose of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("projectPurpose")
        expect(node["inherited"]).to eq("true")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
        expect(node.content).to eq(presenter.project_purpose)
      end
    end

    describe "<provisionalProject>" do
      let(:node) { root.at_xpath("provisionalProject") }

      it "builds a <provisionalProject> element detailing the purpose of the project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("provisionalProject")
        expect(node["inherited"]).to eq("true")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
        expect(node.content).to eq(presenter.provisional_project?.to_s)
      end
    end

    describe "<projectResourceType>" do
      let(:node) { root.at_xpath("projectResourceType") }

      it "builds a <projectResourceType> element detailing the type of research project" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("projectResourceType")
        expect(node["inherited"]).to eq("false")
        expect(node["discoverable"]).to eq("true")
        expect(node["trackingLevel"]).to eq("ResourceRecord")
        expect(node.content).to eq(presenter.project_resource_type)
      end
    end

    describe "<dataUseAgreement>" do
      let(:node) { root.at_xpath("dataUseAgreement") }

      it "builds a <dataUseAgreement> element detailing the use restrictions for the project data" do
        expect(node).to be_a(Nokogiri::XML::Element)
        expect(node.name).to eq("dataUseAgreement")
        expect(node["inherited"]).to eq("true")
        expect(node["discoverable"]).to eq("false")
        expect(node["trackingLevel"]).to eq("InternalUseOnly")
        expect(node.content).to eq(presenter.data_use_agreement?.to_s)
      end
    end

    describe "<projectProvenance>" do
      let(:node) { root.at_xpath("projectProvenance") }

      describe "<submission>" do
        let(:node) { root.at_xpath("projectProvenance/submission") }

        it "builds a <submission> element tracking the latest activity for the project" do
          expect(node).to be_a(Nokogiri::XML::Element)
          expect(node.name).to eq("submission")
        end

        describe "<requestedBy>" do
          let(:node) { root.at_xpath("projectProvenance/submission/requestedBy") }

          it "builds a <requestedBy> element tracking the user requesting resources for the project" do
            expect(node).to be_a(Nokogiri::XML::Element)
            expect(node.name).to eq("requestedBy")
            expect(node["userID"]).to eq(presenter.requested_by)
            expect(node["userIDType"]).to eq("NetID")
          end
        end
        describe "<requestDateTime>" do
          let(:node) { root.at_xpath("projectProvenance/submission/requestDateTime") }

          it "builds a <requestDateTime> element tracking the user requesting resources for the project" do
            expect(node).to be_a(Nokogiri::XML::Element)
            expect(node.name).to eq("requestDateTime")
            expect(node.content).to eq(presenter.request_date_time)
          end
        end

        context "when the project has been approved" do
          let(:status) { ::Project::APPROVED_STATUS }
          let(:approver) { FactoryBot.create(:user, uid: "efg456") }

          # let(:metadata_model) do
          #  hash = {
          #    data_sponsor: data_sponsor.uid,
          #    data_manager: data_manager.uid,
          #    project_directory: "/tigerdata/abcd1/test-project-2",
          #    title: "project 123",
          #    departments: [department], # RDSS test code in fixture data
          #    description: "hello world",
          #    data_user_read_only: [read_only.uid],
          #    data_user_read_write: [read_write.uid],
          #    #status: status,
          #    created_on: Time.current.in_time_zone("America/New_York").iso8601,
          #    created_by: FactoryBot.create(:user).uid,
          #    project_id: "10.34770/az09-0004",
          #    #approval_on: Time.current.in_time_zone("America/New_York").iso8601,
          #    #approved_by: approver.uid,
          #  }
          #  ProjectMetadata.new_from_hash(hash)
          # end

          let(:params) do
            {
              event_note: "Project Approved",
              event_note_message: "This project has been approved."
            }
          end

          before do
            metadata_model.update_with_params(params, approver)
          end

          describe "<approvedBy>" do
            let(:node) { root.at_xpath("projectProvenance/submission/approvedBy") }

            it "builds a <approvedBy> element tracking the approved request for resources for the project" do
              expect(node).to be_a(Nokogiri::XML::Element)
              expect(node.name).to eq("approvedBy")
              expect(node["userID"]).to eq(presenter.approved_by)
              expect(node["userIDType"]).to eq("NetID")
            end
          end

          describe "<approvalDateTime>" do
            let(:node) { root.at_xpath("projectProvenance/submission/approvalDateTime") }

            it "builds a <approvalDateTime> element tracking the approved request for resources for the project" do
              expect(node).to be_a(Nokogiri::XML::Element)
              expect(node.name).to eq("approvalDateTime")
              expect(node.content).to eq(presenter.approval_date_time)
            end
          end
        end
      end
    end

    describe "XSD schema validation" do
      let(:validation_errors) { schema.validate(document) }

      it "validates against the XSD schema document" do
        expect(validation_errors).to be_empty
      end
    end
  end
end
