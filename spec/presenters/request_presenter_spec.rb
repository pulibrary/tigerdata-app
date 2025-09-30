# frozen_string_literal: true
require "rails_helper"

describe RequestPresenter, type: :model, connect_to_mediaflux: false do
  subject(:presenter) { described_class.new(request) }
  let(:current_user) { FactoryBot.create :user, uid: "tigerdatatester" }
  let(:request) { FactoryBot.create :request, requested_by: "tigerdatatester" }

  describe "#eligible_to_edit?" do
    it "allows the requester to edit a draft request" do
      request.state = Request::DRAFT
      expect(presenter.eligible_to_edit?(current_user)).to be true
    end

    it "prevents the requester from editing a submitted request" do
      request.state = Request::SUBMITTED
      expect(presenter.eligible_to_edit?(current_user)).to be false
    end

    context "when the user is a sysadmin" do
      let(:current_user) { FactoryBot.create :sysadmin }
      it "allows a sysadmin to edit a draft request" do
        request.state = Request::DRAFT
        expect(presenter.eligible_to_edit?(current_user)).to be true
      end

      it "allows a sysadmin to edit a submitted request" do
        request.state = Request::SUBMITTED
        expect(presenter.eligible_to_edit?(current_user)).to be true
      end
    end

    context "when the user is a developer" do
      let(:current_user) { FactoryBot.create :developer }
      it "allows a developer to edit a draft request" do
        request.state = Request::DRAFT
        expect(presenter.eligible_to_edit?(current_user)).to be true
      end

      it "allows a developer to edit a submitted request" do
        request.state = Request::SUBMITTED
        expect(presenter.eligible_to_edit?(current_user)).to be true
      end

      it "allows a developer to edit a draft request if they are the requester" do
        request.state = Request::DRAFT
        request.requested_by = current_user.uid
        expect(presenter.eligible_to_edit?(current_user)).to be true
      end

      context "when in production" do
        before do
          allow(Rails.env).to receive(:production?).and_return(true)
        end

        it "prevents a developer to edit a draft request" do
          request.state = Request::DRAFT
          expect(presenter.eligible_to_edit?(current_user)).to be false
        end

        it "allows a developer to edit a draft request if they are the requester" do
          request.state = Request::DRAFT
          request.requested_by = current_user.uid
          expect(presenter.eligible_to_edit?(current_user)).to be true
        end

        it "prevents a developer to edit a submitted request" do
          request.state = Request::SUBMITTED
          expect(presenter.eligible_to_edit?(current_user)).to be false
        end
      end
    end
  end
end
