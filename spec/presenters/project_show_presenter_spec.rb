# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectShowPresenter do
  let!(:data_sponsor) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let!(:data_manager) { FactoryBot.create(:sponsor_and_data_manager, uid: "kl37") }
  let(:ro_user) { FactoryBot.create(:user, uid: "jr5") }
  let(:rw_user) { FactoryBot.create(:user, uid: "cac9") }
  let!(:other_user) { FactoryBot.create(:user, uid: "mjc12") }
  let(:request1) do
    FactoryBot.create :request_project, data_manager: data_manager.uid, data_sponsor: data_sponsor.uid,
                                        user_roles: [{ "uid" => rw_user.uid, "read_only" => false }, { "uid" => ro_user.uid, "read_only" => true }]
  end
  let(:project) { request1.approve(data_sponsor) }
  subject(:presenter) { ProjectShowPresenter.new(project, data_sponsor) }

  describe "#user_has_access?" do
    it "gives access to the right users" do
      expect(presenter.user_has_access?(user: data_sponsor)).to be true
      expect(presenter.user_has_access?(user: data_manager)).to be true
      expect(presenter.user_has_access?(user: ro_user)).to be true
      expect(presenter.user_has_access?(user: rw_user)).to be true
      expect(presenter.user_has_access?(user: other_user)).to be false
    end

    context "handles errors fetching metadata" do
      before do
        allow(project).to receive(:mediaflux_metadata).and_return({})
      end

      it "always prevent access if we don't have access to the metadata" do
        expect(presenter.user_has_access?(user: data_sponsor)).to be false
        expect(presenter.user_has_access?(user: data_manager)).to be false
        expect(presenter.user_has_access?(user: ro_user)).to be false
        expect(presenter.user_has_access?(user: rw_user)).to be false
        expect(presenter.user_has_access?(user: other_user)).to be false
      end
    end
  end

  describe "#file_list_json" do
    let(:project) { test_project_from_path("/princeton/tigerdata/RDSS/Query/CProject") }

    it "returns a JSON string of the file list" do
      parsed = JSON.parse(presenter.file_list_json)
      dir_listing = project.directory_listing(session_id: SystemUser.mediaflux_session)
      project_files = dir_listing[:files]
      last_modified_date = project_files.first.last_modified.strftime("%m/%d/%Y")
      expect(parsed.count).to eq(10)
      expect(parsed.first["name"]).to eq("A0")
      expect(parsed.first["collection"]).to be_falsey
      expect(parsed.first["current_object"]).to be_truthy
      expect(parsed.first["last_modified"]).to eq(last_modified_date)
      expect(parsed.first["name"]).to eq("A0")
      expect(parsed.first["path"]).to eq("/princeton/tigerdata/RDSS/Query/CProject/A0")
      expect(parsed.first["size"]).to eq("10 Bytes")
      expect(parsed.first["asset_count"]).to eq(0)
      expect(parsed.first["folder_size"]).to eq("0 Bytes")
      expect(parsed.first["type"]).to eq("unknown")
      expect(parsed.first["name"]).to eq("A0")
      expect(parsed.first["created_by"].values).to eq ["manager", "", "system"]
      expect(parsed.first["created_on"]).to eq(last_modified_date)
      expect(parsed.last["collection"]).to be_truthy
      expect(parsed.last["current_object"]).to be_falsey
      expect(parsed.last["last_modified"]).to eq(last_modified_date)
      expect(parsed.last["name"]).to eq("n_10000")
      expect(parsed.last["path"]).to eq("/princeton/tigerdata/RDSS/Query/CProject/n_10000")
      expect(parsed.last["size"]).to eq("0 Bytes")
      expect(parsed.last["asset_count"]).to eq(10_000)
      expect(parsed.last["folder_size"]).to eq("98 KB")
      expect(parsed.last["type"]).to eq("collection")
      expect(parsed.last["created_by"].values).to eq ["manager", "", "system"]
      expect(parsed.last["created_on"]).to eq(last_modified_date)
    end
  end
end
