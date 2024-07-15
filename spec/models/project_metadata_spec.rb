# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectMetadata, type: :model do
  let(:current_user) { FactoryBot.create(:user, uid: "hc1234") }
  let(:project) { Project.new }
  let(:project_metadata) { described_class.new }
  let(:hash) do
    {
      data_sponsor: "abc",
      data_manager: "def",
      departments: "dep",
      project_directory: "dir",
      title: "title abc",
      description: "description 123",
      status: "pending"
  }.with_indifferent_access
  end

  let(:default_storage_capacity) do
    { requested: 500, approved: nil }.with_indifferent_access
  end

  let(:default_storage_performance_expectations) do
    { requested: "Standard", approved: nil }.with_indifferent_access
  end

  let(:default_project_purpose ) { "Research"}

  describe "#initialize_from_hash" do
    it "parses basic metadata" do
      project_metadata.initialize_from_hash(hash)
      expect(project_metadata.data_sponsor).to eq("abc")
      expect(project_metadata.data_manager).to eq("def")
      expect(project_metadata.departments).to eq("dep")
      expect(project_metadata.project_directory).to eq("dir")
      expect(project_metadata.title).to eq("title abc")
      expect(project_metadata.description).to eq("description 123")
      expect(project_metadata.status).to eq("pending")
    end

    it "sets the default values when not given" do
      project_metadata.initialize_from_hash(hash)
      expect(project_metadata.storage_capacity[:size].with_indifferent_access).to eq default_storage_capacity
      expect(project_metadata.storage_performance_expectations.with_indifferent_access).to eq default_storage_performance_expectations
      expect(project_metadata.project_purpose).to eq default_project_purpose
    end

    it "overwrites default values when given" do
      hash[:project_purpose] = "Not research"
      project_metadata.initialize_from_hash(hash)
      expect(project_metadata.project_purpose).to eq "Not research"
    end
  end

  describe "#initialize_from_params" do
    it "uses the provided timestamps (when available)" do
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.created_by).to be_blank
      expect(project_metadata.created_on).to be_blank
      expect(project_metadata.updated_on).to be_blank
      expect(project_metadata.updated_by).to be_blank

      hash[:created_on] = Time.current.in_time_zone("America/New_York").iso8601
      hash[:created_by] = "user1"
      hash[:updated_on] = Time.current.in_time_zone("America/New_York").iso8601
      hash[:updated_by] = "user2"
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.created_by).to_not be_blank
      expect(project_metadata.created_on).to_not be_blank
      expect(project_metadata.updated_on).to_not be_blank
      expect(project_metadata.updated_by).to_not be_blank
    end

    it "parses the read only users" do
      hash[:ro_user_1] = "abc"
      hash[:ro_user_counter] = "1"
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.ro_users).to eq(["abc"])
    end

    it "parses empty read only users" do
      hash[:ro_user_counter] = "0"
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.ro_users).to eq([])
    end

    it "parses the read/write users" do
      hash[:rw_user_1] = "rwx"
      hash[:rw_user_counter] = "1"
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.rw_users).to eq(["rwx"])
    end

    it "parses empty read/write users" do
      hash[:rw_user_counter] = "0"
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.rw_users).to eq([])
    end
  end

  describe "#update_with_params" do
    it "sets the values in the params" do
      project_metadata.initialize_from_params(hash)
      expect(project_metadata.title).to eq("title abc")

      # it preserves the original title when no title is given
      hash["title"] = nil
      project_metadata.update_with_params(hash, current_user)
      expect(project_metadata.title).to eq("title abc")

      # changes the title when one is given
      hash["title"] = "title abc again"
      project_metadata.update_with_params(hash, current_user)
      expect(project_metadata.title).to eq("title abc again")
    end
  end

  context "when a project is present" do
    let(:project) { FactoryBot.create :project }

    describe "#approve_project" do
      it "Records the mediaflux id and sets the status to approved" do
        project_metadata = described_class.new(current_user: current_user, project:)
        params = {mediaflux_id: 001,
                  project_directory: project.metadata[:project_directory],
                  storage_capacity: {"size"=>{"approved"=>600,
                  "requested"=>project.metadata[:storage_capacity][:size][:requested]},
                  "unit"=>{"approved"=>"GB", "requested"=>"GB"}},
                  storage_performance_expectations: { requested: "Standard", approved: "Fast" },
                  event_note: "Other",
                  event_note_message: "Message filler"
                  }
        project_metadata.approve_project(params:)

        project.reload

        expect(project.mediaflux_id).not_to be_nil
        expect(project.metadata_json["status"]).to eq Project::APPROVED_STATUS
      end
      it "Creates a Provenance Event: Approval" do
        project_metadata = described_class.new(current_user: current_user, project:)
        params = {mediaflux_id: 001,
                  project_directory: project.metadata[:project_directory],
                  storage_capacity: {"size"=>{"approved"=>600,
                  "requested"=>project.metadata[:storage_capacity][:size][:requested]},
                  "unit"=>{"approved"=>"GB", "requested"=>"GB"}},
                  storage_performance_expectations: { requested: "Standard", approved: "Fast" },
                  event_note: "Other",
                  event_note_message: "Message filler"
                  }
        project_metadata.approve_project(params:) # doesn't call the doi service twice

        project.reload
        expect(project.provenance_events.count).to eq 2
        approval_event = project.provenance_events.first #testing the approval Event
        expect(approval_event.event_type).to eq ProvenanceEvent::APPROVAL_EVENT_TYPE
        expect(approval_event.event_person).to eq current_user.uid
        expect(approval_event.event_details).to eq "Approved by #{current_user.display_name_safe}"
      end
    end

    describe "#activate_project", connect_to_mediaflux: true do
      let(:valid_project) { FactoryBot.create(:project_with_dynamic_directory, project_id: "10.34770/tbd")}
      let(:project_metadata) {described_class.new(current_user:, project: valid_project)}
      after do
        Mediaflux::Http::AssetDestroyRequest.new(session_token: current_user.mediaflux_session, collection: valid_project.mediaflux_id, members: true).resolve
      end
      it "validates the doi for a project" do
        params = { project_directory: valid_project.metadata[:project_directory],
                  storage_capacity: {"size"=>{"approved"=>600,
                  "requested"=>project.metadata[:storage_capacity][:size][:requested]},
                  "unit"=>{"approved"=>"GB", "requested"=>"GB"}},
                  storage_performance_expectations: { requested: "Standard", approved: "Fast" },
                  event_note: "Other",
                  event_note_message: "Message filler"
                  }
        project_metadata.approve_project(params:)

        # create a project in mediaflux
        session_token = current_user.mediaflux_session
        collection_id = valid_project.save_in_mediaflux(session_id: session_token)

        # change the project directory so it will not match up when activated
        original_directory = valid_project.project_directory
        valid_project.metadata_json["project_directory"] = "/abc/123/def"
        valid_project.save!
        valid_project.reload

        #validate that the collection id exists in mediaflux
        project_metadata.activate_project(collection_id:,current_user:)
        expect(valid_project.project_directory).to eq(original_directory)

        expect(valid_project.metadata_json["status"]).to eq Project::ACTIVE_STATUS

        #activate the project by setting the status to active and creating the necessary provenance events
        expect(valid_project.provenance_events.count).to eq 4
        activate_event = valid_project.provenance_events.third #testing the approval Event
        expect(activate_event.event_type).to eq ProvenanceEvent::ACTIVE_EVENT_TYPE
        expect(activate_event.event_person).to eq current_user.uid
        expect(activate_event.event_details).to eq "Activated by Tigerdata Staff"
      end
    end

    # check the logic for not activating when the
    context "non matching doi", connect_to_mediaflux: false do
      let(:metadata) { { id: '', creator: '', description: '', collection: '', path: '', type: '', namespace: '', accumulators: '', project_id: '' } }

      before do
        metadata_request = instance_double(Mediaflux::Http::AssetMetadataRequest, metadata: )
        allow(Mediaflux::Http::AssetMetadataRequest).to receive(:new).and_return(metadata_request)
        logon_request = instance_double(Mediaflux::Http::LogonRequest, session_token: "abc123")
        allow(Mediaflux::Http::LogonRequest).to receive(:new).and_return(logon_request)
      end

      describe "#activate_project", connect_to_mediaflux: true do
        let(:valid_project) { FactoryBot.create(:project_with_dynamic_directory, project_id: "10.34770/tbd")}
        let(:project_metadata) {described_class.new(current_user:, project: valid_project)}
        it "validates the doi for a project and does nothing" do
          params = {mediaflux_id: 001,
                    project_directory: valid_project.metadata[:project_directory],
                    storage_capacity: {"size"=>{"approved"=>600,
                    "requested"=>project.metadata[:storage_capacity][:size][:requested]},
                    "unit"=>{"approved"=>"GB", "requested"=>"GB"}},
                    storage_performance_expectations: { requested: "Standard", approved: "Fast" },
                    event_note: "Other",
                    event_note_message: "Message filler"
                    }
          project_metadata.approve_project(params:)
          # activation should do nothing because the project_id (DOI) will not match
          project_metadata.activate_project(collection_id: "112233", current_user:)

          expect(valid_project.metadata_json["status"]).to eq Project::APPROVED_STATUS
          expect(valid_project.provenance_events.count).to eq 2
        end
      end
    end
  end
end
