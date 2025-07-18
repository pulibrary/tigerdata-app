# frozen_string_literal: true

require "rails_helper"

describe "New Project Request page", type: :system, connect_to_mediaflux: false, js: true do
  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:new_project_request_wizard, true)
  end

  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/requests"
      expect(page).to have_content "Log in"
    end
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
    let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul456", mediaflux_session: SystemUser.mediaflux_session) }
    let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "puladmin", mediaflux_session: SystemUser.mediaflux_session) }
    let(:superuser) { FactoryBot.create(:superuser, uid: "root", mediaflux_session: SystemUser.mediaflux_session) }
    let!(:data_manager) { FactoryBot.create(:data_manager, uid: "pul987", mediaflux_session: SystemUser.mediaflux_session) }
    let(:request) { Request.create(request_title: "abc123", project_title: "project") }
    let(:full_request) do
      Request.create(
        request_type: nil,
        request_title: nil,
        project_title: "Test Project Title",
        created_at: Time.current.in_time_zone("America/New_York").iso8601,
        state: "draft",
        data_sponsor: sponsor_user.uid,
        data_manager: data_manager.uid,
        departments:
          [{ "code" => "77777", "name" => "RDSS-Research Data and Scholarship Services" }, { "code" => "88888", "name" => "PRDS-Princeton Research Data Service" }],
        description: "Test project description",
        parent_folder: "test_parent_folder",
        project_folder: "test_project_folder",
        project_id: nil,
        storage_size: nil,
        requested_by: current_user.uid,
        storage_unit: "GB",
        quota: "500 GB",
        user_roles: [{ "uid" => current_user.uid, "name" => current_user.display_name }]
      )
    end
    let(:bluemountain) do
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
        requested_by: current_user.uid,
        storage_unit: "GB",
        quota: "500 GB",
        user_roles: [{ "uid" => current_user.uid, "name" => current_user.display_name }]
      )
    end
    let(:invalid_request) do
      Request.create
    end

    context "user without a role" do
      it "does not show the New Project Requests page to users without a role" do
        sign_in current_user
        visit "/requests"
        expect(page).to have_content "You do not have access to this page."
      end

      it "does not show the approve button on a single request view for users without a role" do
        sign_in current_user
        put new_project_review_and_submit_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Save")
        expect(response).to redirect_to("#{requests_path}/#{request.id}")
        follow_redirect!
        expect(response.body).not_to have_content("Approve request")
      end
    end

    context "sponsor_user" do
      it "does not show the New Project Requests page to data sponsors" do
        sign_in sponsor_user
        visit "/requests"
        expect(page).to have_content "You do not have access to this page."
      end
      it "does not show the approve button on a single request view for data sponsors" do
        sign_in sponsor_user
        put new_project_review_and_submit_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Save")
        expect(response).to redirect_to("#{requests_path}/#{request.id}")
        follow_redirect!
        expect(response.body).not_to have_content("Approve request")
      end
    end

    context "data_manager" do
      it "does not show the New Project Requests page to data managers" do
        sign_in data_manager
        visit "/requests"
        expect(page).to have_content "You do not have access to this page."
      end
      it "does not show the approve button on a single request view for data managers" do
        sign_in data_manager
        put new_project_review_and_submit_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Save")
        expect(response).to redirect_to("#{requests_path}/#{request.id}")
        follow_redirect!
        expect(response.body).not_to have_content("Approve request")
      end
    end

    context "sysadmin_user" do
      it "shows the New Project Requests page to sysadmin users" do
        sign_in sysadmin_user
        visit "/requests"
        expect(page).to have_content "New Project Requests"
      end
      it "shows the approve button on a single request view for sysadmins" do
        sign_in sysadmin_user
        put new_project_review_and_submit_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Save")
        expect(response).to redirect_to("#{requests_path}/#{request.id}")
        follow_redirect!
        expect(response.body).to have_content("Approve request")
      end
      it "creates a project with a DOI when a request is approved" do
        sign_in sysadmin_user
        visit "#{requests_path}/#{full_request.id}"
        expect(page).to have_content("Approve request")
        click_on "Approve request"
        expect(page).to have_css("#project-details-heading")
        expect(page).to have_content("The request has been approved and this project was created in the TigerData web portal. The request has been processed and deleted.")
        project = Project.last
        expect(project.title).to eq("Test Project Title")
        expect(project.metadata_json["project_id"]).to eq("10.34770/tbd")
        expect(project).to be_valid
      end
      it "creates a project with BlueMountain fixture data when the request is approved" do
        sign_in sysadmin_user
        visit "#{requests_path}/#{bluemountain.id}"
        expect(page).to have_content("Approve request")
        click_on "Approve request"
        expect(page).to have_css("#project-details-heading")
        expect(page).to have_content("The request has been approved and this project was created in the TigerData web portal. The request has been processed and deleted.")
        project = Project.last
        expect(project.title).to eq("Blue Mountain")
        expect(project).to be_valid
      end

      it "forwards back to the request review page when the request is not ready to submit" do
        sign_in sysadmin_user
        visit "#{requests_path}/#{invalid_request.id}"
        expect(page).to have_content("Approve request")
        click_on "Approve request"
        expect(page).to have_content("Review")
        within(".project-title") do
          expect(page).to have_content("cannot be empty")
        end
        within(".project-description") do
          expect(page).to have_content("cannot be empty")
        end
        within(".departments") do
          expect(page).to have_content("cannot be empty")
        end
        within(".data-manager") do
          expect(page).to have_content("cannot be empty")
        end
        within(".data-sponsor") do
          expect(page).to have_content("cannot be empty")
        end
        within(".project-folder") do
          expect(page).to have_content("cannot be empty")
        end
      end
    end

    context "superuser" do
      it "shows the New Project Requests page to superusers" do
        sign_in superuser
        visit "/requests"
        expect(page).to have_content "New Project Requests"
      end
      it "shows the approve button on a single request view for superusers" do
        sign_in superuser
        put new_project_review_and_submit_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Save")
        expect(response).to redirect_to("#{requests_path}/#{request.id}")
        follow_redirect!
        expect(response.body).to have_content("Approve request")
      end
    end
  end
end
