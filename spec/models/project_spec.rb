# frozen_string_literal: true
require "rails_helper"

RSpec.describe Project, type: :model, connect_to_mediaflux: true do
  let(:user) { FactoryBot.create(:user, uid: "abc123", mediaflux_session: SystemUser.mediaflux_session) }

  describe "#sponsored_projects" do
    let(:sponsor) { FactoryBot.create(:user, uid: "hc1234") }
    before do
      FactoryBot.create(:project, title: "project 111", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 222", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 333", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 444", data_sponsor: user.uid)
    end

    it "returns projects for the sponsor" do
      sponsored_projects = described_class.sponsored_projects("hc1234")
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 111" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 222" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 333" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 444" }).to be nil
    end
  end
  describe "#managed_projects" do
    let(:manager) { FactoryBot.create(:user, uid: "hc1234") }
    before do
      FactoryBot.create(:project, title: "project 111", data_manager: manager.uid)
      FactoryBot.create(:project, title: "project 222", data_manager: manager.uid)
      FactoryBot.create(:project, title: "project 333", data_manager: manager.uid)
      FactoryBot.create(:project, title: "project 444", data_manager: user.uid)
    end

    it "returns projects for the manager" do
      managed_projects = described_class.managed_projects("hc1234")
      expect(managed_projects.find { |project| project.metadata[:title] == "project 111" }).not_to be nil
      expect(managed_projects.find { |project| project.metadata[:title] == "project 222" }).not_to be nil
      expect(managed_projects.find { |project| project.metadata[:title] == "project 333" }).not_to be nil
      expect(managed_projects.find { |project| project.metadata[:title] == "project 444" }).to be nil
    end
  end

  describe "#data_users" do
    let(:data_user) { FactoryBot.create(:user, uid: "hc1234") }
    before do
      FactoryBot.create(:project, title: "project 111", data_user_read_only: [data_user.uid])
      FactoryBot.create(:project, title: "project 222", data_user_read_only: [user.uid, data_user.uid])
      FactoryBot.create(:project, title: "project 333", data_user_read_write: [data_user.uid])
      FactoryBot.create(:project, title: "project 444", data_user_read_only: [user.uid])      
    end

    it "returns projects for the data users" do
      data_user_projects = described_class.data_user_projects("hc1234")
      expect(data_user_projects.find { |project| project.metadata_model.title == "project 111" }).not_to be nil
      expect(data_user_projects.find { |project| project.metadata_model.title == "project 222" }).not_to be nil
      expect(data_user_projects.find { |project| project.metadata_model.title == "project 333" }).not_to be nil
      expect(data_user_projects.find { |project| project.metadata_model.title == "project 444" }).to be nil
    end
  end

  describe "#users_projects" do
    let(:test_user) { FactoryBot.create(:user, uid: "hc1234") }
    before do
      FactoryBot.create(:project, title: "project 111", data_manager: test_user.uid)
      FactoryBot.create(:project, title: "project 222", data_sponsor: test_user.uid)
      FactoryBot.create(:project, title: "project 333", data_user_read_only: [user.uid, test_user.uid])
      FactoryBot.create(:project, title: "project 444", data_user_read_write: [test_user.uid])
      FactoryBot.create(:project, title: "project 555", data_user_read_only: [user.uid])      
    end

    it "returns projects for the data users" do
      user_projects = described_class.users_projects(test_user)
      expect(user_projects.find { |project| project.metadata_model.title == "project 111" }).to be nil
      expect(user_projects.find { |project| project.metadata_model.title == "project 222" }).to be nil
      expect(user_projects.find { |project| project.metadata_model.title == "project 333" }).not_to be nil
      expect(user_projects.find { |project| project.metadata_model.title == "project 444" }).not_to be nil
      expect(user_projects.find { |project| project.metadata_model.title == "project 555" }).to be nil
    end

    context "user is eligible sponsor" do
      before do
        test_user.update(eligible_sponsor: true)
      end

      it "returns projects for the data users" do
        user_projects = described_class.users_projects(test_user)
        expect(user_projects.find { |project| project.metadata_model.title == "project 111" }).to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 222" }).not_to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 333" }).not_to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 444" }).not_to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 555" }).to be nil
      end
    end

    context "user is eligible manager" do
      before do
        test_user.update(eligible_manager: true)
      end

      it "returns projects for the data users" do
        user_projects = described_class.users_projects(test_user)
        expect(user_projects.find { |project| project.metadata_model.title == "project 111" }).not_to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 222" }).to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 333" }).not_to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 444" }).not_to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 555" }).to be nil
      end
    end

    context "user is eligible sponsor and manager" do
      before do
        test_user.update(eligible_manager: true, eligible_sponsor: true)
      end

      it "returns projects for the data users" do
        user_projects = described_class.users_projects(test_user)
        expect(user_projects.find { |project| project.metadata_model.title == "project 111" }).not_to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 222" }).not_to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 333" }).not_to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 444" }).not_to be nil
        expect(user_projects.find { |project| project.metadata_model.title == "project 555" }).to be nil
      end
    end
  end

  describe "#pending_projects" do
    before do
      FactoryBot.create(:project, title: "project 111", mediaflux_id: 1111)
      FactoryBot.create(:project, title: "project 222", mediaflux_id: 2222)
      FactoryBot.create(:project, title: "project 333")
    end

    it "returns projects that are not in mediaflux" do
      pending_projects = described_class.pending_projects
      expect(pending_projects.find { |project| project.metadata_model.title == "project 111" and project.mediaflux_id == 1111 }).to be nil
      expect(pending_projects.find { |project| project.metadata_model.title == "project 222" and project.mediaflux_id == 2222 }).to be nil
      expect(pending_projects.find { |project| project.metadata_model.title == "project 333" and project.mediaflux_id.nil? }).not_to be nil
    end
  end

  describe "#approved_projects" do
    before do
      FactoryBot.create(:project, title: "project 111", mediaflux_id: 1111)
      FactoryBot.create(:project, title: "project 222", mediaflux_id: 2222)
      FactoryBot.create(:project, title: "project 333")
    end

    it "returns projects that are not in mediaflux" do
      approved_projects = described_class.approved_projects
      expect(approved_projects.find { |project| project.metadata_model.title == "project 111" and project.mediaflux_id == 1111 }).not_to be nil
      expect(approved_projects.find { |project| project.metadata_model.title == "project 222" and project.mediaflux_id == 2222 }).not_to be nil
      expect(approved_projects.find { |project| project.metadata_model.title == "project 333" and project.mediaflux_id.nil? }).to be nil
    end
  end

  describe "#provenance_events" do
    let(:project) { FactoryBot.create(:project) }
    let(:submission_event) { FactoryBot.create(:submission_event, project: project) }
    it "has many provenance events" do
      expect(project.provenance_events).to eq [submission_event]
    end
    it "only creates one provenance event" do
      project.provenance_events.create(event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE, event_person: project.metadata["created_by"],
                                       event_details: "Requested by #{project.metadata_json['data_sponsor']}")
      expect(project.provenance_events.count).to eq 1
    end
  end

  describe "#file_list" do
    let(:manager) { FactoryBot.create(:user, uid: "hc1234", mediaflux_session: SystemUser.mediaflux_session) }
    let(:project) do
      project = FactoryBot.create(:approved_project, title: "project 111", data_manager: manager.uid)
      project.mediaflux_id = nil
      project
    end

    before do
      # Save the project in mediaflux
      project.save_in_mediaflux(user: manager)

      # create a collection so it can be filtered
      Mediaflux::AssetCreateRequest.new(session_token: manager.mediaflux_session, name: "sub-collectoion", pid: project.mediaflux_id).resolve


      # Create files for the project in mediaflux using test asset create request
      Mediaflux::TestAssetCreateRequest.new(session_token: manager.mediaflux_session, parent_id: project.mediaflux_id, pattern: "Real_Among_Random.txt").resolve
      Mediaflux::TestAssetCreateRequest.new(session_token: manager.mediaflux_session, parent_id: project.mediaflux_id, count: 7, pattern: "#{FFaker::Book.title}.txt").resolve
    end

    after do
      Mediaflux::AssetDestroyRequest.new(session_token: manager.mediaflux_session, collection: project.mediaflux_id, members: true).resolve
    end

    it "fetches the file list" do
      file_list = project.file_list(session_id: manager.mediaflux_session, size: 10)
      expect(file_list[:files].count).to eq 8
      expect(file_list[:files][0].name).to eq "Real_Among_Random.txt0"
      expect(file_list[:files][0].path).to eq "/td-test-001/test/tigerdata/big-data/Real_Among_Random.txt0"
      expect(file_list[:files][0].size).to be 100
      expect(file_list[:files][0].collection).to be false
      expect(file_list[:files][0].last_modified).to_not be nil
    end
  end

  describe "#mediaflux_metadata" do
    let(:project) { FactoryBot.create(:project) }
    it "calls out to mediaflux once" do
      metadata_request = instance_double Mediaflux::AssetMetadataRequest, metadata: {}
      allow(Mediaflux::AssetMetadataRequest).to receive(:new).and_return(metadata_request)
      project.mediaflux_metadata(session_id: "")
      project.mediaflux_metadata(session_id: "") # intentionally calling twice, to see if mediaflux is only called once.
      expect(Mediaflux::AssetMetadataRequest).to have_received(:new).once
    end
  end

  describe "#save_in_mediaflux" do
    let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
    let(:project) { FactoryBot.create(:project_with_doi) }
    it "calls ProjectMediaflux to create the project and save the id" do
      expect(project.mediaflux_id).to be nil
      project.save_in_mediaflux(user: user)
      expect(project.mediaflux_id).not_to be nil
    end

    context "when the projects has already beed saved" do
      before do
        project.save_in_mediaflux(user: user)
      end
      it "calls out to mediuaflux with an update " do
        project.metadata_model.title = "New title"
        expect { project.save_in_mediaflux(user: user) }.not_to raise_error
      end
    end
  end

  describe "#project_directory" do
    it "includes the full path" do
      project = FactoryBot.create(:project)
      expect(project.project_directory).to eq("#{Rails.configuration.mediaflux['api_root_ns']}/#{project.metadata_json['project_directory']}")
    end

    it "does not include the default path if a path is already included" do
      project = FactoryBot.create(:project, project_directory: "/123/abc/directory")
      expect(project.project_directory).to eq("/123/abc/directory")
    end

    it "makes sure the directory is safe" do
      project = FactoryBot.create(:project, project_directory: "directory?")
      expect(project.project_directory).to eq("#{Rails.configuration.mediaflux['api_root_ns']}/directory-")
      project.metadata_model.project_directory = "direc tory "
      expect(project.project_directory).to eq("#{Rails.configuration.mediaflux['api_root_ns']}/direc-tory")
      project = FactoryBot.create(:project, project_directory: "direc/tory/")
      project.metadata_model.project_directory = "direc/tory/"
      expect(project.project_directory).to eq("#{Rails.configuration.mediaflux['api_root_ns']}/direc-tory-")
      project.metadata_model.project_directory = "/direc/tory/"
      expect(project.project_directory).to eq("/direc/tory/")
    end
  end

  describe "#project_directory_short" do
    it "does not include the full path" do
      project = FactoryBot.create(:project, project_directory: "/123/abc/directory")
      expect(project.project_directory_short).to eq("directory")
    end
  end

  describe "#project_directory_parent_path" do
    it "does not include the directory" do
      project = FactoryBot.create(:project, project_directory: "/123/abc/directory")
      expect(project.project_directory_parent_path).to eq("/123/abc")
    end

    it "defaults to the configured vaule if no directory is present" do
      project = FactoryBot.create(:project, project_directory: "directory")
      expect(project.project_directory_parent_path).to eq(Mediaflux::Connection.root_namespace)
    end
  end

  describe "#pending?" do
    it "checks the status" do
      project = FactoryBot.create(:project)
      expect(project).to be_pending
      project.metadata_model.status = Project::APPROVED_STATUS
      expect(project).not_to be_pending
    end
  end

  describe "#create!" do
    let(:datacite_stub) { instance_double(PULDatacite, draft_doi: "aaabbb123") }
    let(:current_user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
    let(:project) { FactoryBot.create(:project) }

    before do
      allow(PULDatacite).to receive(:new).and_return(datacite_stub)
    end

    context "DOI minting" do
      it "does not mint a DOI when project is invalid" do
        initial_metadata = ProjectMetadata.new_from_hash({})
        project.create!(initial_metadata: initial_metadata, user: current_user)
        expect(datacite_stub).to_not have_received(:draft_doi)
      end

      it "does not mint a new DOI when the project has a project_id" do
        project.metadata_model.update_with_params({"project_id" => "123"},  current_user)
        doi = project.create!(initial_metadata: project.metadata_model, user: current_user)
        expect(datacite_stub).to_not have_received(:draft_doi)
        expect(doi).to eq "123"
      end

      it "mints a DOI when needed" do
        project.metadata_model.update_with_params({"project_id" => ProjectMetadata::DOI_NOT_MINTED},  current_user)
        project.create!(initial_metadata: project.metadata_model, user: current_user)
        expect(datacite_stub).to have_received(:draft_doi)
      end
    end

    context "Provenance events" do
      it "creates the provenance events when creating a new project" do
        project.metadata_model.update_with_params({"project_id" => ProjectMetadata::DOI_NOT_MINTED},  current_user)
        project.create!(initial_metadata: project.metadata_model, user: current_user)

        expect(project.provenance_events.count).to eq 2
        submission_event = project.provenance_events.first #testing the Submission Event
        expect(submission_event.event_type).to eq ProvenanceEvent::SUBMISSION_EVENT_TYPE
        expect(submission_event.event_person).to eq current_user.uid
        expect(submission_event.event_details).to eq "Requested by #{current_user.display_name_safe}"

        status_update_event = project.provenance_events.last #testing the Status Update Event when the project is first submitted, #TODO: will need a separate test for when a project is approved by an admin
        expect(status_update_event.event_type).to eq ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE
        expect(status_update_event.event_person).to eq current_user.uid
        expect(status_update_event.event_details).to eq "The Status of this project has been set to pending"
      end
    end
  end

  describe "#approve!" do
    let(:datacite_stub) { instance_double(PULDatacite, draft_doi: "aaabbb123") }
    let(:current_user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
    let(:project) { FactoryBot.create(:project) }

    before do
      allow(PULDatacite).to receive(:new).and_return(datacite_stub)
    end

    it "Records the mediaflux id and sets the status to approved" do
      project.metadata_model.update_with_params({"project_id" => "123"},  current_user)
      project.create!(initial_metadata: project.metadata_model, user: current_user)

      project.approve!(mediaflux_id: 9876, current_user: current_user)
      project.reload

      expect(project.mediaflux_id).not_to be_nil
      expect(project.metadata_model.status).to eq Project::APPROVED_STATUS
    end

    it "creates the provenance events when creating a new project" do
      project.metadata_model.update_with_params({"project_id" => ProjectMetadata::DOI_NOT_MINTED}, current_user)
      project.create!(initial_metadata: project.metadata_model, user: current_user)
      project.approve!(mediaflux_id: 9876, current_user: current_user)
      project.reload


      expect(project.mediaflux_id).not_to be_nil
      expect(project.metadata_model.status).to eq Project::APPROVED_STATUS

      expect(project.provenance_events.count).to eq 4
      approval_event = project.provenance_events.select { |event| event.event_type == ProvenanceEvent::APPROVAL_EVENT_TYPE}.first

      expect(approval_event.event_type).to eq ProvenanceEvent::APPROVAL_EVENT_TYPE
      expect(approval_event.event_person).to eq current_user.uid
      expect(approval_event.event_details).to eq "Approved by #{current_user.display_name_safe}"
    end
  end

  describe "#activate!" do
  let(:project) { FactoryBot.create(:project_with_dynamic_directory, project_id: "10.34770/tbd")}
  let(:current_user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:project_metadata) {project.metadata_model}
  after do
    Mediaflux::AssetDestroyRequest.new(session_token: current_user.mediaflux_session, collection: project.mediaflux_id, members: true).resolve
  end
  it "activates a project" do
    project.create!(initial_metadata: project.metadata_model, user: current_user)

    # create a project in mediaflux
    collection_id = project.save_in_mediaflux(user: current_user)
    project.approve!(mediaflux_id: collection_id, current_user: current_user)

    #validate that the collection id exists in mediaflux
    project.activate!(collection_id:,current_user:)
    expect(project.mediaflux_id).to eq(collection_id)
    expect(project.metadata_model.status).to eq Project::ACTIVE_STATUS

    #activate the project by setting the status to active and creating the necessary provenance events
    activate_event = project.provenance_events.select { |event| event.event_type == ProvenanceEvent::ACTIVE_EVENT_TYPE}.first  #testing the approval Event
    expect(activate_event.event_type).to eq ProvenanceEvent::ACTIVE_EVENT_TYPE
    expect(activate_event.event_person).to eq current_user.uid
    expect(activate_event.event_details).to eq "Activated by Tigerdata Staff"
  end

  it "tries to activate a project that has a mismatched doi" do
      project.create!(initial_metadata: project.metadata_model, user: current_user)

      # create a project in mediaflux
      collection_id = project.save_in_mediaflux(user: current_user)
      project.approve!(mediaflux_id: collection_id, current_user: current_user)

      # change the doi so it will not match up when activated
      project.metadata_model.project_id = "90.34770/xyz"
      project.save!

      #validate that the collection id exists in mediaflux
      project.activate!(collection_id:,current_user:)
      expect(project.metadata_model.status).to_not eq Project::ACTIVE_STATUS
  end
end
end
