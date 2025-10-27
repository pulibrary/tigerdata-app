# frozen_string_literal: true
require "rails_helper"

RSpec.describe Project, type: :model, connect_to_mediaflux: true do
  let(:user) { FactoryBot.create(:user, uid: "kl37", mediaflux_session: SystemUser.mediaflux_session) }
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  describe "project lists" do
    let(:test_user) { sponsor_and_data_manager_user }
    before do
      request1 = FactoryBot.create :request_project, project_title: "project 111", data_manager: test_user.uid, data_sponsor: test_user.uid
      request1.approve(sponsor_and_data_manager_user)
      request2 = FactoryBot.create(:request_project, project_title: "project 222", data_sponsor: test_user.uid)
      request2.approve(sponsor_and_data_manager_user)
      request3 = FactoryBot.create(:request_project, project_title: "project 333", user_roles: [{ "uid" => user.uid, "read_only" => true }, { "uid" => test_user.uid, "read_only" => true }])
      request3.approve(sponsor_and_data_manager_user)
      request4 = FactoryBot.create(:request_project, project_title: "project 444", user_roles: [{ "uid" => test_user.uid, "read_only" => false }])
      request4.approve(sponsor_and_data_manager_user)
      request5 = FactoryBot.create(:request_project, project_title: "project 555", data_manager: user.uid, data_sponsor: user.uid, user_roles: [{ "uid" => user.uid, "read_only" => true }])
      request5.approve(sponsor_and_data_manager_user)
    end

    it "returns _all_ projects for the logged in user" do
      all_projects = described_class.all_projects(test_user)

      # Finds ALL the projects we added...
      expect(all_projects.find { |project| project[:title] == "project 111" }).not_to be nil
      expect(all_projects.find { |project| project[:title] == "project 222" }).not_to be nil
      expect(all_projects.find { |project| project[:title] == "project 333" }).not_to be nil
      expect(all_projects.find { |project| project[:title] == "project 444" }).not_to be nil
      expect(all_projects.find { |project| project[:title] == "project 555" }).not_to be nil

      # ...plus a project that comes predefined in the Docker image
      expect(all_projects.find { |project| project[:directory] == "tigerdata/RDSS/testing-project" }).not_to be nil
    end

    it "returns _only_ projects where the logged in user has a role (manager, sponsor, data user)" do
      user_projects = described_class.users_projects(test_user)

      # Finds only the projects where the user has a role (manager, sponsor, or data user)
      expect(user_projects.count).to be 4
      expect(user_projects.find { |project| project[:title] == "project 111" }).not_to be nil
      expect(user_projects.find { |project| project[:title] == "project 222" }).not_to be nil
      expect(user_projects.find { |project| project[:title] == "project 333" }).not_to be nil
      expect(user_projects.find { |project| project[:title] == "project 444" }).not_to be nil

      # make sure we don't get the project where the user does not have a role
      expect(user_projects.find { |project| project[:title] == "project 555" }).to be nil

      # ...and make sure it excludes the predefined project in the Docker image because we know
      # for sure our user does not have a role on it.
      expect(user_projects.find { |project| project[:directory] == "tigerdata/RDSS/testing-project" }).to be nil
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
    let(:manager) { sponsor_and_data_manager_user }
    let!(:project) do
      request = FactoryBot.create(:request_project)
      request.approve(manager)
    end

    before do
      # create a collection so it can be filtered
      Mediaflux::AssetCreateRequest.new(session_token: manager.mediaflux_session, name: "sub-collectoion", pid: project.mediaflux_id).resolve

      # Create files for the project in mediaflux using test asset create request
      Mediaflux::TestAssetCreateRequest.new(session_token: manager.mediaflux_session, parent_id: project.mediaflux_id, pattern: "Real_Among_Random.txt").resolve
      Mediaflux::TestAssetCreateRequest.new(session_token: manager.mediaflux_session, parent_id: project.mediaflux_id, count: 7, pattern: "#{FFaker::Book.title}.txt").resolve
    end

    it "fetches the file list",
    :integration do
      file_list = project.file_list(session_id: manager.mediaflux_session, size: 10)
      expect(file_list[:files].count).to eq 8
      expect(file_list[:files][0].name).to eq "Real_Among_Random.txt0"
      expect(file_list[:files][0].path).to eq "/princeton/#{project.project_directory}/Real_Among_Random.txt0"
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
        project.metadata_model.update_with_params({ "project_id" => "123" }, current_user)
        doi = project.create!(initial_metadata: project.metadata_model, user: current_user)
        expect(datacite_stub).to_not have_received(:draft_doi)
        expect(doi).to eq "123"
      end

      it "mints a DOI when needed" do
        project.metadata_model.update_with_params({ "project_id" => ProjectMetadata::DOI_NOT_MINTED }, current_user)
        project.create!(initial_metadata: project.metadata_model, user: current_user)
        expect(datacite_stub).to have_received(:draft_doi)
      end
    end

    context "Provenance events" do
      it "creates the provenance events when creating a new project" do
        project.metadata_model.update_with_params({ "project_id" => ProjectMetadata::DOI_NOT_MINTED }, current_user)
        project.create!(initial_metadata: project.metadata_model, user: current_user)

        expect(project.provenance_events.count).to eq 2
        submission_event = project.provenance_events.first # testing the Submission Event
        expect(submission_event.event_type).to eq ProvenanceEvent::SUBMISSION_EVENT_TYPE
        expect(submission_event.event_person).to eq current_user.uid
        expect(submission_event.event_details).to eq "Requested by #{current_user.display_name_safe}"

        # testing the Status Update Event when the project is first submitted,
        # TODO: will need a separate test for when a project is approved by an admin
        status_update_event = project.provenance_events.last
        expect(status_update_event.event_type).to eq ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE
        expect(status_update_event.event_person).to eq current_user.uid
        expect(status_update_event.event_details).to eq "The Status of this project has been set to pending"
      end
    end
  end

  describe ".default_storage_unit" do
    it "returns the default storage unit of KB" do
      expect(described_class.default_storage_unit).to eq("KB")
    end
  end

  describe ".default_storage_usage" do
    it "returns the default storage usage of 0 units" do
      expect(described_class.default_storage_usage).to eq("0 KB")
    end
  end
end
