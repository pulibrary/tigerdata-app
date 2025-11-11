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
end
