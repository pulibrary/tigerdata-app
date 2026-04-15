# frozen_string_literal: true
require "rails_helper"

describe DashboardPresenter, type: :model, connect_to_mediaflux: false do
  subject(:presenter) do
    current_user.mediaflux_session = SystemUser.mediaflux_session # ensure the presenter can make mediaflux calls as the current user
    described_class.new(current_user: current_user)
  end

  let(:current_user) { sponsor_and_data_manager }
  # tigerdatatester is created when we load the test projects from mediaflux, see spec/support/project_in_mediaflux.rb
  let(:sponsor_and_data_manager) { User.find_by(uid: "tigerdatatester") }

  let(:other_user) { User.find_by(uid: "kl37")} # user is created when we load the test projects from mediaflux, see spec/support/project_in_mediaflux.rb

  let(:request1) { FactoryBot.create :request_project, data_manager: sponsor_and_data_manager.uid, data_sponsor: other_user.uid, requested_by: other_user.uid }
  let(:request2) { FactoryBot.create :request_project, data_manager: other_user.uid, data_sponsor: sponsor_and_data_manager.uid, requested_by: other_user.uid }
  let(:request3) do
    FactoryBot.create :request_project, data_manager: other_user.uid, data_sponsor: other_user.uid, user_roles: [{ "uid" => sponsor_and_data_manager.uid, "read_only" => true }],
                                        requested_by: other_user.uid
  end
  let(:request4) { FactoryBot.create :request_project, data_manager: other_user.uid, data_sponsor: other_user.uid, requested_by: other_user.uid }

  let!(:project1) { test_project_from_path("/princeton/tigerdata/RDSS/Query/AProject") }
  let!(:project2) do
    project = test_project_from_path("/princeton/tigerdata/RDSS/Query/BProject")
    project.updated_at = ActiveSupport::TimeZone.new("America/New_York").yesterday
    project.save!
    project
  end

  let!(:project3) do
    project = test_project_from_path("/princeton/tigerdata/RDSS/Query/CProject")
    project.updated_at = ActiveSupport::TimeZone.new("America/New_York").tomorrow
    project.save!
    project
  end
  let!(:project4) { test_project_from_path("/princeton/tigerdata/RDSS/testing-project") }

  describe "#all_projects" do
    it "returns an empty array for a normal user" do
      expect(presenter.all_projects).to eq([])
    end

    context "for a sysadmin" do
      before do
        sponsor_and_data_manager.developer = true # so that is detected as a sysadmin
        sponsor_and_data_manager.save!
      end

      it "returns the list of all projects, sorted" do
        expect(presenter.all_projects.count).to eq(4)
        expect(presenter.all_projects.map(&:id)).to eq([project3.id, project4.id, project1.id, project2.id])
      end
    end
  end

  describe "dashboard_projects" do
    it "returns the list of the user's projects, sorted" do
      project_list = presenter.dashboard_projects
      expect(project_list.count).to eq(4)
      expect(project_list.map(&:id)).to eq([project3.id, project4.id, project1.id, project2.id])
    end
  end

  describe "#role" do
    let(:libtigerdatadev) { User.find_by(uid: "libtigerdatadev") }
    let(:current_user){ libtigerdatadev }
    let(:tigerdatatester) { User.find_by(uid: "tigerdatatester") }
    let(:developer) { User.find_by(uid: "kl37") }

    it "detects the proper roles for each project" do
      projects = presenter.dashboard_projects
      expect(projects.map(&:id)).to eq([project3.id, project4.id, project1.id, project2.id])
      expect(projects[0].role(libtigerdatadev)).to be "Data Manager"
      expect(projects[0].role(tigerdatatester)).to be "Sponsor"
      expect(projects[0].role(developer)).to be "Data User"
    end
  end

  describe "my_inventory_requests" do
    it "returns the requests" do
      inv_req = FileInventoryRequest.create!(user_id: sponsor_and_data_manager.id, project_id: project1.id, job_id: 123, state: InventoryRequest::COMPLETED,
                                             request_details: { project_title: project1.title }, completion_time: 1.day.ago)
      inv_req2 = FileInventoryRequest.create!(user_id: sponsor_and_data_manager.id, project_id: project1.id, job_id: 123, state: InventoryRequest::PENDING,
                                              request_details: { project_title: project1.title }, completion_time: nil)
      # Leading underscore to show that the request is intentionally unused, and should be ignored by linting tools
      _inv_req3 = FileInventoryRequest.create!(user_id: other_user.id, project_id: project1.id, job_id: 123, state: InventoryRequest::PENDING,
                                               request_details: { project_title: project1.title }, completion_time: nil)
      expect(presenter.my_inventory_requests.count).to eq(2)
      expect(presenter.my_inventory_requests.map(&:id)).to eq([inv_req.id, inv_req2.id])
    end
  end

  describe "requests" do
    before do
      FactoryBot.create :request, requested_by: "tigerdatatester"
      FactoryBot.create :request, requested_by: "tigerdatatester"
      FactoryBot.create :request, requested_by: "tigerdatatester", state: NewProjectRequest::SUBMITTED
    end

    it "filters draft and submitted requests" do
      expect(presenter.my_draft_requests.count).to eq(2)
      expect(presenter.my_submitted_requests.count).to eq(1)
    end
  end

  describe "#requests_to_approve" do
    let(:sysadmin) { FactoryBot.create :sysadmin, uid: "sysadmin", mediaflux_session: SystemUser.mediaflux_session }
    let(:presenter_for_sysadmin) { described_class.new(current_user: sysadmin) }

    before do
      FactoryBot.create :request, state: NewProjectRequest::SUBMITTED
      FactoryBot.create :request, state: NewProjectRequest::SUBMITTED
      FactoryBot.create :request, state: NewProjectRequest::DRAFT
    end

    it "returns submitted requests for a sysadmin" do
      expect(presenter_for_sysadmin.requests_to_approve.count).to eq(2)
    end

    it "returns an empty array for a non-sysadmin" do
      expect(presenter.requests_to_approve).to eq([])
    end
  end
end
