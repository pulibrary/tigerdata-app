# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project, type: :model, connect_to_mediaflux: true do
  let(:user) { FactoryBot.create(:user, uid: "kl37", mediaflux_session: SystemUser.mediaflux_session) }
  let(:user2) { FactoryBot.create(:user, uid: "libtigerdatadev", mediaflux_session: SystemUser.mediaflux_session) }
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  describe "the mediaflux id" do
    # This solves https://github.com/pulibrary/tigerdata-app/issues/2830
    # ActiveModel::RangeError:
    # 2224309126 is out of range for ActiveModel::Type::Integer with limit 4 bytes
    it "can handle at least a number larger than 4 bytes" do
      project = FactoryBot.create(:project, mediaflux_id: 2_224_309_126)
      expect(project.id).not_to be_nil
    end
  end

  describe "#provenance_events" do
    let(:project) { FactoryBot.create(:project) }
    let(:project_metadata) { ProjectMetadata.new(project) }
    let(:submission_event) { FactoryBot.create(:submission_event, project: project) }

    it "has many provenance events" do
      expect(project.provenance_events).to eq [submission_event]
    end

    it "only creates one provenance event" do
      project.provenance_events.create(event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE, event_person: project_metadata.created_by,
                                       event_details: "Requested by #{project_metadata.data_sponsor}")
      expect(project.provenance_events.count).to eq 1
    end
  end

  describe "#directory_listing" do
    let(:manager) { sponsor_and_data_manager_user }
    let!(:project) { test_project_from_path("/princeton/tigerdata/RDSS/Query/CProject") }

    it "fetches the directory listing",
       :integration do
      directory_files_list = project.directory_listing(session_id: manager.mediaflux_session, size: 50)
      expect(directory_files_list[:files].count).to eq 10
      expect(directory_files_list[:files][0].name).to eq "A0"
      expect(directory_files_list[:files][0].path).to eq "/princeton/tigerdata/RDSS/Query/CProject/A0"
      expect(directory_files_list[:files][0].size).to be 10
      expect(directory_files_list[:files][0].collection).to be false
      expect(directory_files_list[:files][0].last_modified).to_not be nil
    end
  end
end
