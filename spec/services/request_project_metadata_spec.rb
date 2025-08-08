# frozen_string_literal: true
require "rails_helper"

RSpec.describe RequestProjectMetadata do
  let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
  let(:data_manager) { FactoryBot.create(:data_manager, uid: "pul987", mediaflux_session: SystemUser.mediaflux_session) }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul456", mediaflux_session: SystemUser.mediaflux_session) }
  let(:request) do
    Request.create(
      request_type: nil,
      request_title: nil,
      project_title: "Blue Mountain",
      created_at: Time.current.in_time_zone("America/New_York").iso8601,
      state: "draft",
      data_sponsor: sponsor_user.uid,
      data_manager: data_manager.uid,
      departments:
        [{ "code" => "41000", "name" => "LIB-PU Library" }],
      description: "This collection contains important periodicals of the European avant-garde.",
      parent_folder: "pul",
      project_folder: "bluemountain",
      project_id: nil,
      storage_size: nil,
      requested_by: nil,
      storage_unit: nil,
      quota: "500 GB",
      user_roles: [{ "uid" => current_user.uid, "name" => current_user.display_name }]
    )
  end

  describe "##convert" do
    it "returns the correct metadata for the project" do
      project_metadata = RequestProjectMetadata.convert(request)
      expect(project_metadata[:title]).to eq("Blue Mountain")
      expect(project_metadata[:description]).to eq("This collection contains important periodicals of the European avant-garde.")
      expect(project_metadata[:status]).to eq(Project::PENDING_STATUS)
      expect(project_metadata[:data_sponsor]).to eq(sponsor_user.uid)
      expect(project_metadata[:data_manager]).to eq(data_manager.uid)
      expect(project_metadata[:departments]).to eq(["LIB-PU Library"])
      expect(project_metadata[:data_user_read_only]).to eq([current_user.uid])
      expect(project_metadata[:project_directory]).to eq("#{Rails.configuration.mediaflux['api_root']}/pul/bluemountain")
      expect(project_metadata[:storage_capacity][:size]).to eq({ approved: "500.0", requested: "500.0" })
      expect(project_metadata[:storage_capacity][:unit]).to eq({ approved: "GB", requested: "GB" })
      expect(project_metadata[:storage_performance_expectations]).to eq({ requested: "Standard", approved: "Standard" })
      expect(project_metadata[:created_by]).to be_nil
      expect(project_metadata[:created_on]).to eq(request.created_at)
      expect(project_metadata[:project_id]).to eq(ProjectMetadata::DOI_NOT_MINTED)
    end

    context "the storage is custom" do
      let(:request) do
        Request.create(
          request_type: nil,
          request_title: nil,
          project_title: "Blue Mountain",
          created_at: Time.current.in_time_zone("America/New_York").iso8601,
          state: "draft",
          data_sponsor: sponsor_user.uid,
          data_manager: data_manager.uid,
          departments:
            [{ "code" => "41000", "name" => "LIB-PU Library" }],
          description: "This collection contains important periodicals of the European avant-garde.",
          parent_folder: "pul",
          project_folder: "bluemountain",
          project_id: nil,
          storage_size: 30,
          requested_by: nil,
          storage_unit: "TB",
          quota: "custom",
          user_roles: [{ "uid" => current_user.uid, "name" => current_user.display_name }]
        )
      end

      it "returns the correct metadata for the project" do
        project_metadata = RequestProjectMetadata.convert(request)
        expect(project_metadata[:title]).to eq("Blue Mountain")
        expect(project_metadata[:description]).to eq("This collection contains important periodicals of the European avant-garde.")
        expect(project_metadata[:status]).to eq(Project::PENDING_STATUS)
        expect(project_metadata[:data_sponsor]).to eq(sponsor_user.uid)
        expect(project_metadata[:data_manager]).to eq(data_manager.uid)
        expect(project_metadata[:departments]).to eq(["LIB-PU Library"])
        expect(project_metadata[:data_user_read_only]).to eq([current_user.uid])
        expect(project_metadata[:project_directory]).to eq("#{Rails.configuration.mediaflux['api_root']}/pul/bluemountain")
        expect(project_metadata[:storage_capacity][:size]).to eq({ approved: "30.0", requested: "30.0" })
        expect(project_metadata[:storage_capacity][:unit]).to eq({ approved: "TB", requested: "TB" })
        expect(project_metadata[:storage_performance_expectations]).to eq({ requested: "Standard", approved: "Standard" })
        expect(project_metadata[:created_by]).to be_nil
        expect(project_metadata[:created_on]).to eq(request.created_at)
        expect(project_metadata[:project_id]).to eq(ProjectMetadata::DOI_NOT_MINTED)
      end
    end
  end
end
