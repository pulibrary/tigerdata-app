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

  describe "#data_sponsor" do
    let(:current_user) { FactoryBot.create :user }
    let(:request) { FactoryBot.create :request, data_sponsor: current_user.uid }
    it "returns the full name of the data sponsor" do
      expect(presenter.data_sponsor).to eq(current_user.display_name_safe)
    end
  end

  describe "#data_manager" do
    let(:current_user) { FactoryBot.create :user }
    let(:request) { FactoryBot.create :request, data_manager: current_user.uid }
    it "returns the full name of the data manager" do
      expect(presenter.data_manager).to eq(current_user.display_name_safe)
    end
  end

  describe "#data_manager empty" do
    let(:current_user) { FactoryBot.create :user }
    let(:request) { FactoryBot.create :request, data_manager: "" }
    it "handles empty users correctly" do
      expect(presenter.data_manager).to eq("")
    end
  end

  describe "#user_list" do
    let(:current_user) { FactoryBot.create :user }
    let(:request) { FactoryBot.create :request, user_roles: [{ "uid" => current_user.uid.to_s, "name" => current_user.display_name_safe, "read_only" => true }] }
    it "returns a list of the full names of the data users and their uids" do
      expect(presenter.user_list).to eq("#{current_user.display_name_safe} ")
    end
  end

  describe "#user_list empty" do
    let(:current_user) { FactoryBot.create :user }
    let(:request) { FactoryBot.create :request, user_roles: [] }
    it "handles empty users correctly" do
      expect(presenter.user_list).to eq("")
    end
  end

  describe "#departments_list" do
    let(:current_user) { FactoryBot.create :user }
    let(:request) do
      FactoryBot.create :request, departments: [{ "code" => "77777", "name" => "RDSS-Research Data and Scholarship Services" }, { "code" => "88888", "name" => "PRDS-Princeton Research Data Service" }]
    end
    it "returns a list of the full names of the data users and their uids" do
      expect(presenter.departments_list).to eq("RDSS-Research Data and Scholarship Services (77777), PRDS-Princeton Research Data Service (88888)")
    end
  end

  describe "#departments_list empty" do
    let(:current_user) { FactoryBot.create :user }
    let(:request) do
      FactoryBot.create :request, departments: []
    end
    it "handles empty departments correctly" do
      expect(presenter.departments_list).to eq("")
    end
  end

  describe "#full_name" do
    let(:current_user) { FactoryBot.create :user }
    it "returns the full name for a valid uid" do
      expect(presenter.full_name(current_user.uid)).to eq(current_user.display_name_safe)
    end

    it "returns the uid if the full name is not found" do
      current_user.display_name = nil
      current_user.given_name = nil
      current_user.family_name = nil
      current_user.save!
      expect(presenter.full_name(current_user.uid)).to eq(current_user.uid)
    end

    it "returns an empty string if the uid is nil" do
      expect(presenter.full_name(nil)).to eq("")
    end
  end
end
