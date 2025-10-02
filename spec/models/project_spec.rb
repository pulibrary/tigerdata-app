# frozen_string_literal: true
require "rails_helper"

RSpec.describe Project, type: :model, connect_to_mediaflux: true do
  let(:user) { FactoryBot.create(:user, uid: "abc123", mediaflux_session: SystemUser.mediaflux_session) }
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  describe "#sponsored_projects" do
    let(:sponsor) { sponsor_and_data_manager_user }
    before do
      FactoryBot.create(:project, title: "project 111", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 222", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 333", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 444", data_sponsor: user.uid)
    end

    it "returns projects for the sponsor" do
      sponsored_projects = described_class.sponsored_projects("tigerdatatester")
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 111" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 222" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 333" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 444" }).to be nil
    end
  end
  describe "#managed_projects" do
    let(:manager) { sponsor_and_data_manager_user }
    before do
      FactoryBot.create(:project, title: "project 111", data_manager: manager.uid)
      FactoryBot.create(:project, title: "project 222", data_manager: manager.uid)
      FactoryBot.create(:project, title: "project 333", data_manager: manager.uid)
      FactoryBot.create(:project, title: "project 444", data_manager: user.uid)
    end

    it "returns projects for the manager" do
      managed_projects = described_class.managed_projects("tigerdatatester")
      expect(managed_projects.find { |project| project.metadata[:title] == "project 111" }).not_to be nil
      expect(managed_projects.find { |project| project.metadata[:title] == "project 222" }).not_to be nil
      expect(managed_projects.find { |project| project.metadata[:title] == "project 333" }).not_to be nil
      expect(managed_projects.find { |project| project.metadata[:title] == "project 444" }).to be nil
    end
  end

  describe "#users_projects" do
    let(:test_user) { FactoryBot.create(:user, uid: "kl37") }
    before do
      FactoryBot.create(:project, title: "project 111", data_manager: test_user.uid)
      FactoryBot.create(:project, title: "project 222", data_sponsor: test_user.uid)
      FactoryBot.create(:project, title: "project 333", data_user_read_only: [user.uid, test_user.uid])
      FactoryBot.create(:project, title: "project 444", data_user_read_write: [test_user.uid])
      FactoryBot.create(:project, title: "project 555", data_user_read_only: [user.uid])
    end

    it "returns projects for the data users" do
      user_projects = described_class.users_projects(test_user)
      expect(user_projects.find { |project| project.metadata_model.title == "project 111" }).not_to be nil
      expect(user_projects.find { |project| project.metadata_model.title == "project 222" }).not_to be nil
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
        expect(user_projects.find { |project| project.metadata_model.title == "project 111" }).not_to be nil
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
        expect(user_projects.find { |project| project.metadata_model.title == "project 222" }).not_to be nil
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

  describe "#all_projects" do
    before do
      FactoryBot.create(:project, title: "project 111", mediaflux_id: 1111)
      FactoryBot.create(:project, title: "project 222", mediaflux_id: 2222)
      FactoryBot.create(:project, title: "project 333")
    end

    it "returns projects that are in mediaflux, which is all of them" do
      all_projects = described_class.all_projects
      expect(all_projects.find { |project| project.metadata_model.title == "project 111" and project.mediaflux_id == 1111 }).not_to be nil
      expect(all_projects.find { |project| project.metadata_model.title == "project 222" and project.mediaflux_id == 2222 }).not_to be nil
      expect(all_projects.find { |project| project.metadata_model.title == "project 333" and project.mediaflux_id.nil? }).not_to be nil
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
