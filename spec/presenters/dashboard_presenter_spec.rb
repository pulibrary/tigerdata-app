# frozen_string_literal: true
require "rails_helper"

describe DashboardPresenter, type: :model, connect_to_mediaflux: false do
  subject(:presenter) { described_class.new(current_user:) }

  let(:current_user) { FactoryBot.create :user, uid: "tigerdatatester" }
  let(:other_user) { FactoryBot.create :user }
  let(:project1) { FactoryBot.create :project, data_manager: other_user.uid, data_sponsor: other_user.uid }
  let(:project2) { FactoryBot.create :project, data_user_read_only: ["tigerdatatester"], updated_at:  ActiveSupport::TimeZone.new("America/New_York").yesterday }

  before do
    # make sure the database is setup before the tests
    current_user
    other_user
    project1
    project2
  end

  describe "#all_projects" do
    it "returns an empty array for a normal user" do
      expect(presenter.all_projects).to eq([])
    end

    context "for a sysadmin" do
      let(:current_user) { FactoryBot.create :sysadmin, uid: "tigerdatatester" }

      it "returns the list of all projects in sorted order" do
        expect(presenter.all_projects.count).to eq(2)
        expect(presenter.all_projects.map(&:id)).to eq([project1.id, project2.id])
      end
    end
  end

  describe "dashboard_projects" do
      it "returns the list of all of the user's projects in sorted order" do
        project3 = FactoryBot.create :project, data_user_read_only: ["tigerdatatester"], updated_at:  ActiveSupport::TimeZone.new("America/New_York").tomorrow
        expect(presenter.dashboard_projects.count).to eq(2)
        expect(presenter.dashboard_projects.map(&:id)).to eq([project3.id, project2.id])
      end
  end

  describe "my_inventory_requests" do
    it "returns the requests" do
      inv_req = FileInventoryRequest.create!(user_id: current_user.id, project_id: project1.id, job_id: 123, state: UserRequest::COMPLETED,
                                     request_details: { project_title: project1.title }, completion_time: 1.day.ago)
      inv_req2 = FileInventoryRequest.create!(user_id: current_user.id, project_id: project1.id, job_id: 123, state: UserRequest::PENDING,
                                     request_details: { project_title: project1.title }, completion_time: nil)
      inv_req3 = FileInventoryRequest.create!(user_id: other_user.id, project_id: project1.id, job_id: 123, state: UserRequest::PENDING,
                                     request_details: { project_title: project1.title }, completion_time: nil)
      expect(presenter.my_inventory_requests.count).to eq(2)
      expect(presenter.my_inventory_requests.map(&:id)).to eq([inv_req.id, inv_req2.id])
    end

  end
end
