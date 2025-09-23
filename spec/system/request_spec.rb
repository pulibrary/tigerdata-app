# frozen_string_literal: true

require "rails_helper"

describe "New Project Request page", type: :system, connect_to_mediaflux: false, js: true do
  let!(:sponsor_and_data_manager) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/requests"
      expect(page).to have_content "Log in"
    end
  end

  context "authenticated user" do
    let(:current_user) { sponsor_and_data_manager }
    let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "kl37", mediaflux_session: SystemUser.mediaflux_session) }
    let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "puladmin", mediaflux_session: SystemUser.mediaflux_session) }
    let(:developer) { FactoryBot.create(:developer, uid: "root", mediaflux_session: SystemUser.mediaflux_session) }
    let!(:data_manager) { FactoryBot.create(:data_manager, uid: "rl3667", mediaflux_session: SystemUser.mediaflux_session) }
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
        project_purpose: "research",
        parent_folder: random_project_directory,
        project_folder: "test_project_folder",
        project_id: nil,
        storage_size: nil,
        requested_by: current_user.uid,
        storage_unit: "GB",
        quota: "500 GB",
        user_roles: [{ "uid" => current_user.uid, "name" => current_user.display_name }]
      )
    end
    let(:custom_quota_request) do
      Request.create(
        request_type: nil,
        request_title: nil,
        project_title: "Custom Quota Project",
        created_at: Time.current.in_time_zone("America/New_York").iso8601,
        state: "draft",
        data_sponsor: sponsor_user.uid,
        data_manager: data_manager.uid,
        departments:
          [{ "code" => "77777", "name" => "RDSS-Research Data and Scholarship Services" }, { "code" => "88888", "name" => "PRDS-Princeton Research Data Service" }],
        description: "Test project description",
        project_purpose: "research",
        parent_folder: random_project_directory,
        project_folder: "test_project_folder",
        project_id: nil,
        storage_size: "1725",
        requested_by: current_user.uid,
        storage_unit: "TB",
        quota: "custom",
        user_roles: [{ "uid" => current_user.uid, "name" => current_user.display_name }]
      )
    end
    let(:bluemountain) do
      Request.create(
        request_type: nil,
        request_title: nil,
        project_title: "Blue Mountain",
        created_at: Time.current.in_time_zone("America/New_York").iso8601,
        state: Request::SUBMITTED,
        data_sponsor: sponsor_user.uid,
        data_manager: data_manager.uid,
        departments:
          [{ "code" => "41000", "name" => "LIB-PU Library" }],
        description: "This collection contains important periodicals of the European avant-garde.",
        project_purpose: "teaching",
        parent_folder: "pul",
        project_folder: "#{random_project_directory}-bluemountain",
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
      it "does not show the approve button on a single request view for sysadmins if the request has not been submitted" do
        sign_in sysadmin_user
        put new_project_review_and_submit_save_url(request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Save")
        expect(response).to redirect_to("#{requests_path}/#{request.id}")
        follow_redirect!
        # it does not show a approve request unless the request is submitted
        expect(response.body).not_to have_content("Approve request")
        expect(response.body).to have_content("Edit request")
      end
      it "shows the approve button on a single submitted request view for sysadmins" do
        sign_in sysadmin_user
        put new_project_review_and_submit_save_url(full_request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Next")
        expect(response).to redirect_to(request_submit_path)
        follow_redirect!
        expect(response.body).to have_content("Your new project request is submitted")
        sign_in sysadmin_user
        visit "/requests/#{Request.last.id}"
        # it does not show a approve request unless the request is submitted
        expect(page).to have_link("Approve request")
        expect(page).not_to have_content("Edit request")
        expect(page).to have_content("Edit submitted request")
      end
      it "shows the names of the data users on a single submitted request that includes data user(s)" do
        sign_in sysadmin_user
        visit "#{requests_path}/#{full_request.id}"
        expect(page).to have_css("#request-data-users")
        expect(page).to have_content("tigerdatatester")
      end
      it "shows the departments on a single submitted request that includes departments" do
        sign_in sysadmin_user
        visit "#{requests_path}/#{full_request.id}"
        expect(page).to have_css("#request-data-departments")
        expect(page).to have_content("88888")
        expect(page).to have_content("RDSS-Research Data and Scholarship Services")
      end
      it "creates a project with a DOI when a request is approved", integration: true do
        sign_in sysadmin_user
        # a request must be submitted before it can be approved
        full_request.state = Request::SUBMITTED
        full_request.save
        visit "#{requests_path}/#{full_request.id}"
        expect(page).to have_content("Approve request")
        expect(page).to have_content("500.0 GB")
        click_on "Approve request"
        expect(page).to have_css("#project-details-heading")
        expect(page).to have_content("The request has been approved and this project was created in the TigerData web portal. The request has been processed and deleted.")
        project = Project.last
        expect(project.title).to eq("Test Project Title")
        expect(project.metadata_json["project_id"]).to eq("10.34770/tbd")
        expect(project).to be_valid
      end
      it "creates a project with BlueMountain fixture data when the request is approved", integration: true do
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
        visit approve_request_path(invalid_request.id)
        expect(page).to have_content("Review")
        within(".project-title") do
          expect(page).to have_content("cannot be empty")
        end
        within(".project-description") do
          expect(page).to have_content("cannot be empty")
        end
        within(".project-purpose") do
          expect(page).to have_content("select a project purpose")
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

      it "shows the custom quota on the request review page", integration: true do
        sign_in sysadmin_user
        custom_quota_request.state = Request::SUBMITTED
        custom_quota_request.save
        visit "#{requests_path}/#{custom_quota_request.id}"
        expect(custom_quota_request.quota).to eq("custom")
        expect(page).to have_content("Approve request")
        expect(page).to have_content("1725.0 TB")
      end
    end

    context "developer" do
      it "shows the New Project Requests page to developers" do
        sign_in developer
        visit "/requests"
        expect(page).to have_content "New Project Requests"
      end

      it "shows the approve button on a single request view for developers" do
        sign_in developer
        put new_project_review_and_submit_save_url(full_request.id, request: { request_title: "new title", project_title: "new project" }, commit: "Next")
        expect(response).to redirect_to(request_submit_path)
        sign_in sysadmin_user
        visit "/requests/#{Request.last.id}"
        expect(page).to have_content("Approve request")
      end
    end
  end
end
