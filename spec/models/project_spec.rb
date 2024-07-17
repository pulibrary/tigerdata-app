# frozen_string_literal: true
require "rails_helper"

RSpec.describe Project, type: :model, stub_mediaflux: true do
  describe "#sponsored_projects" do
    let(:sponsor) { FactoryBot.create(:user, uid: "hc1234") }
    before do
      FactoryBot.create(:project, title: "project 111", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 222", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 333", data_sponsor: sponsor.uid)
    end

    it "returns projects for the sponsor" do
      sponsored_projects = described_class.sponsored_projects("hc1234")
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 111" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 222" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 444" }).to be nil
    end
  end
  describe "#managed_projects" do
    let(:manager) { FactoryBot.create(:user, uid: "hc1234") }
    before do
      FactoryBot.create(:project, title: "project 111", data_manager: manager.uid)
      FactoryBot.create(:project, title: "project 222", data_manager: manager.uid)
      FactoryBot.create(:project, title: "project 333", data_manager: manager.uid)
    end

    it "returns projects for the manager" do
      managed_projects = described_class.managed_projects("hc1234")
      expect(managed_projects.find { |project| project.metadata[:title] == "project 111" }).not_to be nil
      expect(managed_projects.find { |project| project.metadata[:title] == "project 222" }).not_to be nil
      expect(managed_projects.find { |project| project.metadata[:title] == "project 444" }).to be nil
    end
  end

  describe "#data_users" do
    let(:data_user) { FactoryBot.create(:user, uid: "hc1234") }
    before do
      FactoryBot.create(:project, title: "project 111", data_user_read_only: [data_user.uid])
      FactoryBot.create(:project, title: "project 222", data_user_read_only: [data_user.uid])
      FactoryBot.create(:project, title: "project 333", data_user_read_only: [data_user.uid])
    end

    it "returns projects for the data users" do
      data_user_projects = described_class.data_user_projects("hc1234")
      expect(data_user_projects.find { |project| project.metadata_model.title == "project 111" }).not_to be nil
      expect(data_user_projects.find { |project| project.metadata_model.title == "project 222" }).not_to be nil
      expect(data_user_projects.find { |project| project.metadata_model.title == "project 444" }).to be nil
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
    let(:manager) { FactoryBot.create(:user, uid: "hc1234") }
    let(:project) do
      project = FactoryBot.create(:project, title: "project 111", data_manager: manager.uid)
      project.mediaflux_id = "123"
      project
    end

    before do
      # define query to fetch file list
      # (returns iterator 456)
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query\" session=\"test-session-token\">\n    <args>\n      "\
        "<where>asset in static collection or subcollection of 123</where>\n      <action>get-values</action>\n      "\
        "<xpath ename=\"name\">name</xpath>\n      <xpath ename=\"path\">path</xpath>\n      <xpath ename=\"total-size\">content/@total-size</xpath>\n      "\
        "<xpath ename=\"mtime\">mtime</xpath>\n      <xpath ename=\"collection\">@collection</xpath>\n      <as>iterator</as>\n    </args>\n  </service>\n</request>\n",
              headers: {
                "Accept" => "*/*",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "Connection" => "keep-alive",
                "Content-Type" => "text/xml; charset=utf-8",
                "Keep-Alive" => "30",
                "User-Agent" => "Ruby"
              })
        .to_return(status: 200, body: "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\r\n<response><reply><result><iterator>456</iterator></result></reply></response>", headers: {})

      # fetch file list using iterator 456
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query.iterate\" session=\"test-session-token\">\n    "\
        "<args>\n      <id>456</id>\n      <size>10</size>\n    </args>\n  </service>\n</request>\n",
              headers: {
                "Accept" => "*/*",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "Connection" => "keep-alive",
                "Content-Type" => "text/xml; charset=utf-8",
                "Keep-Alive" => "30",
                "User-Agent" => "Ruby"
              })
        .to_return(status: 200, body: fixture_file("files/iterator_response_get_values.xml"), headers: {})

      # destroy the iterator
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
        .with(body: /asset.query.iterator.destroy/,
              headers: {
                "Accept" => "*/*",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "Connection" => "keep-alive",
                "Content-Type" => "text/xml; charset=utf-8",
                "Keep-Alive" => "30",
                "User-Agent" => "Ruby"
              })
        .to_return(status: 200, body: "", headers: {})
    end

    it "fetches the file list" do
      file_list = project.file_list(session_id: "test-session-token", size: 10)
      expect(file_list[:files].count).to eq 8
      expect(file_list[:files][0].name).to eq "file1.txt"
      expect(file_list[:files][0].path).to eq "/td-demo-001/localbig-ns/localbig/file1.txt"
      expect(file_list[:files][0].size).to be 141
      expect(file_list[:files][0].collection).to be false
      expect(file_list[:files][0].last_modified).to eq "2024-02-12T11:43:25-05:00"
    end
  end

  describe "#mediaflux_metadata" do
    let(:project) { FactoryBot.create(:project) }
    it "calls out to mediaflux once" do
      metadata_request = instance_double Mediaflux::Http::AssetMetadataRequest, metadata: {}
      allow(Mediaflux::Http::AssetMetadataRequest).to receive(:new).and_return(metadata_request)
      project.mediaflux_metadata(session_id: "")
      project.mediaflux_metadata(session_id: "") # intentionally calling twice, to see if mediaflux is only called once.
      expect(Mediaflux::Http::AssetMetadataRequest).to have_received(:new).once
    end
  end

  describe "#save_in_mediaflux", connect_to_mediaflux: true do
    let(:user) { FactoryBot.create(:user) }
    let(:project) { FactoryBot.create(:project_with_doi) }
    it "calls ProjectMediaflux to create the project and save the id" do
      expect(project.mediaflux_id).to be nil
      project.save_in_mediaflux(session_id: user.mediaflux_session)
      expect(project.mediaflux_id).not_to be nil
    end

    context "when the projects has already beed saved" do
      before do
        project.save_in_mediaflux(session_id: user.mediaflux_session)
      end
      it "calls out to mediuaflux with an update " do
        project.metadata_model.title = "New title"
        expect { project.save_in_mediaflux(session_id: user.mediaflux_session) }.not_to raise_error
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
      expect(project.project_directory_parent_path).to eq(Mediaflux::Http::Connection.root_namespace)
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
    let(:current_user) { FactoryBot.create(:user) }
    let(:project) { FactoryBot.create(:project) }

    before do
      allow(PULDatacite).to receive(:new).and_return(datacite_stub)
    end

    context "DOI minting" do
      it "attempts to mint a DOI when project_id is empty" do
        initial_metadata = ProjectMetadata.new_from_hash({})
        project.create!(initial_metadata: initial_metadata, user: current_user)
        expect(datacite_stub).to have_received(:draft_doi)
      end

      it "does not mint a new DOI when the project has a project_id" do
        project.metadata_model.update_with_params({"project_id" => "123"},  current_user)
        doi = project.create!(initial_metadata: project.metadata_model, user: current_user)
        expect(datacite_stub).not_to have_received(:draft_doi)
        expect(doi).to eq "123"
      end
    end

    context "Provenance events" do
      it "creates the provenance events when creating a new project" do
        project.metadata_model.update_with_params({"project_id" => "123"},  current_user)
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
    let(:current_user) { FactoryBot.create(:user) }
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
      project.metadata_model.update_with_params({"project_id" => "123"},  current_user)
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

  describe "#activate!", connect_to_mediaflux: true do
  let(:project) { FactoryBot.create(:project_with_dynamic_directory, project_id: "10.34770/tbd")}
  let(:current_user) { FactoryBot.create(:user) }
  let(:project_metadata) {project.metadata_model}
  after do
    Mediaflux::Http::AssetDestroyRequest.new(session_token: current_user.mediaflux_session, collection: project.mediaflux_id, members: true).resolve
  end
  it "activates a project" do
    project.create!(initial_metadata: project.metadata_model, user: current_user)

    # create a project in mediaflux
    session_token = current_user.mediaflux_session
    collection_id = project.save_in_mediaflux(session_id: session_token)
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
      session_token = current_user.mediaflux_session
      collection_id = project.save_in_mediaflux(session_id: session_token)
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
