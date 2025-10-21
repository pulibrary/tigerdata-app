# frozen_string_literal: true
require "rails_helper"

describe DashboardPresenter, type: :model, connect_to_mediaflux: false do
  subject(:presenter) { described_class.new(current_user:) }

  let(:current_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:other_user) { FactoryBot.create :user, uid: "kl37" }
  let(:request1) { FactoryBot.create :request_project, data_manager: other_user.uid, data_sponsor: other_user.uid }
  let(:request2) { FactoryBot.create :request_project, user_roles: [{"uid" => "tigerdatatester", "read_only" => true}] }

  let!(:project1) { request1.approve(current_user) }
  let!(:project2) {
    project = request2.approve(current_user)
    project.updated_at = ActiveSupport::TimeZone.new("America/New_York").yesterday
    project.save!
    project
  }

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
        byebug
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

  describe "requests" do
    before do
      FactoryBot.create :request, requested_by: "tigerdatatester"
      FactoryBot.create :request, requested_by: "tigerdatatester"
      FactoryBot.create :request, requested_by: "tigerdatatester", state: Request::SUBMITTED
    end

    it "filters draft and submitted requests" do
      expect(presenter.my_draft_requests.count).to eq(2)
      expect(presenter.my_submitted_requests.count).to eq(1)
    end
  end
end
