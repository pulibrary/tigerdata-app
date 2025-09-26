# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", connect_to_mediaflux: true, js: true do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit dashboard_path
      expect(page).to have_content "You need to sign in or sign up before continuing."
    end
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
    let(:admin_user) { FactoryBot.create(:sysadmin, uid: "admin123") }
    let(:other_user) { FactoryBot.create(:user, uid: "zz123") }
    let(:no_projects_user) { FactoryBot.create(:user, uid: "qw999") }
    let(:no_projects_sponsor) { FactoryBot.create(:project_sponsor, uid: "gg717") }
    let(:docker_response) { Mediaflux::EXPECTED_VERSION }

    let(:project_222) { FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: current_user.uid, title: "project 222") }

    before do
      FactoryBot.create(:project, data_sponsor: current_user.uid, data_manager: other_user.uid, title: "project 111")
      project_222
      FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: other_user.uid, data_user_read_only: [current_user.uid], title: "project 333")
      FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: other_user.uid, title: "project 444")
      allow(File).to receive(:size) { 1_234_567 }
    end

    context "current user dashboard - non admin user" do
      it "shows the welcome message and 'Log out' button" do
        sign_in current_user
        visit dashboard_path

        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        click_link current_user.uid.to_s
        expect(page).to have_content "Log out"
      end

      it "shows the Mediflux version on the home page for a logged in user" do
        sign_in current_user
        visit dashboard_path
        sleep(1)
        expect(page).to have_content(docker_response)
      end

      it "shows the projects based on the user's role" do
        sign_in current_user
        visit dashboard_path

        expect(page).to have_content "Sponsor"
        expect(page).to have_content "project 111"
        expect(page).to have_content "Data Manager"
        expect(page).to have_content "project 222"
        expect(page).to have_content "Data User"
        expect(page).to have_content "project 333"
        # The current user has no access to this project so we don't expect to see it
        expect(page).not_to have_content "project 444"
      end

      it "shows the latests downloads available" do
        approved_project = Project.users_projects(current_user).first
        FileInventoryJob.new(user_id: current_user.id, project_id: approved_project.id, mediaflux_session: current_user.mediaflux_session).perform_now
        FileInventoryRequest.create(user_id: current_user.id, project_id: approved_project.id, job_id: "ccbb63c0-a8cd-47b7-8445-5d85e9c80977", state: UserRequest::FAILED,
                                    request_details: { project_title: approved_project.title }, completion_time: Time.current.in_time_zone("America/New_York"))
        sign_in current_user
        visit dashboard_path

        expect(page).to have_content "Latest Downloads"
        expect(page).to have_link approved_project.title
        expect(page).to have_content "Expires in 7 days"
        expect(page).to have_content "1.18 MB"
        expect(page).to have_content "The download failed to complete"
      end

      it "hides the 'Administration' tab" do
        sign_in current_user
        visit dashboard_path

        expect(page).to have_content "Welcome, #{current_user.given_name}!"
        expect(page).not_to have_content "Administration"
      end

      context "the user signed in is an eligible sponsor" do
        it "shows the projects based on the user's role" do
          current_user.update(eligible_sponsor: true)

          sign_in current_user
          visit dashboard_path
          expect(page).to have_content "Sponsor"
          expect(page).to have_content "project 111"
          expect(page).to have_content "Data Manager"
          expect(page).to have_content "project 222"
          expect(page).to have_content "Data User"
          expect(page).to have_content "project 333"
          # The current user has no access to this project so we don't expect to see it
          expect(page).not_to have_content "project 444"
          expect(page).to be_axe_clean
            .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
            .skipping(:'color-contrast') # false positives
            .excluding(".tt-hint") # Issue is in typeahead.js library
        end
      end

      context "the user signed in is an eligible manager" do
        it "shows the projects based on the user's role" do
          current_user.update(eligible_manager: true)

          sign_in current_user
          visit dashboard_path
          expect(page).to have_content "Sponsor"
          expect(page).to have_content "project 111"
          expect(page).to have_content "Data Manager"
          expect(page).to have_content "project 222"
          expect(page).to have_content "Data User"
          expect(page).to have_content "project 333"
          # The current user has no access to this project so we don't expect to see it
          expect(page).not_to have_content "project 444"
        end
      end

      it "allows for navigation back to user dashboard when clicking logo" do
        sign_in current_user
        visit project_path(project_222)
        expect(page).to have_content "project 222"
        page.find(:css, "#logo").click
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
      end

      it "paginates the projects; 8 per page" do
        projects = (1..17).map { FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: other_user.uid, data_user_read_only: [current_user.uid]) }
        sign_in current_user
        visit dashboard_path
        expect(page).to have_content("8 out of 20 shown")
        find("a.paginate_button", text: 2).click
        expect(page).to have_content(projects.sort_by(&:updated_at).reverse[8].title)
        find("a.paginate_button", text: 3).click
        expect(page).to have_content(projects.sort_by(&:updated_at).reverse.last.title)
        find("a.paginate_button", text: "<").click
        expect(page).to have_content(projects.sort_by(&:updated_at).reverse[14].title)
        find("a.paginate_button", text: "<").click
        expect(page).to have_content(projects.sort_by(&:updated_at).reverse.first.title)
      end

      it "should not display the New Project Request even if the feature is activated" do
        sign_in current_user
        visit dashboard_path
        expect(page).not_to have_content("New Project Request")
      end
    end

    context "for a user without any projects" do
      it "shows the 'Log out' button" do
        sign_in no_projects_user
        visit dashboard_path
        expect(page).to have_content("Welcome, #{no_projects_user.given_name}!")
        expect(page).to have_content("No projects")
        click_link no_projects_user.uid.to_s
        expect(page).to have_content "Log out"
      end

      it "shows no downloads available" do
        sign_in no_projects_user
        visit dashboard_path
        expect(page).to have_content("No downloads available")
      end
    end

    context "with the developer role" do
      let(:current_user) { FactoryBot.create(:developer, uid: "xxx999") }

      it "shows the 'Project Requests' button" do
        sign_in admin_user
        visit dashboard_path
        expect(page).to have_content("Welcome, #{admin_user.given_name}!")
        expect(page).not_to have_content "Please log in"
        expect(page).to have_content "Requests"
      end

      it "shows the system administrator dashboard", js: true do
        sign_in current_user
        visit dashboard_path
        expect(page).to have_content "project 111"
        expect(page).not_to have_content "project 444"
        click_on "Administration"
        expect(page).to have_content "project 111"
        expect(page).to have_content "project 444"
        expect(page).to have_content("Approved Projects")
      end

      it "renders the 'Administration' tab" do
        sign_in current_user
        visit dashboard_path
        expect(page).to have_content "Administration"
      end
    end

    context "for tester-trainers" do
      it "shows the emulation bar" do
        sign_in current_user
        current_user.trainer = true
        current_user.save!
        visit "/dashboard"
        expect(page).to have_select("emulation_menu")
      end
      it "displays sponsored projects when emulating a data sponsor" do
        sign_in current_user
        current_user.trainer = true
        current_user.save!
        visit dashboard_path
        select "Data Sponsor", from: "emulation_menu"
        within("#projects-listing") do
          expect(page).to have_content("Sponsor")
          expect(page).to have_content("Data Manager")
          expect(page).to have_content("Data User")
        end
      end
      it "displays sponsored projects when emulating a data manager" do
        sign_in current_user
        current_user.trainer = true
        current_user.save!
        visit dashboard_path
        select "Data Manager", from: "emulation_menu"
        within("#projects-listing") do
          expect(page).to have_content("Sponsor")
          expect(page).to have_content("Data Manager")
          expect(page).to have_content("Data User")
        end
        expect(page).to be_axe_clean
          .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
          .skipping(:'color-contrast') # false positives
          .excluding(".tt-hint") # Issue is in typeahead.js library
      end

      it "hides the 'Administration' tab" do
        sign_in current_user
        current_user.trainer = true
        current_user.save!

        visit dashboard_path
        expect(page).not_to have_content "Administration"
      end
    end

    context "with the sysadmin role" do
      let(:current_user) { FactoryBot.create(:sysadmin, uid: "xxx999") }

      it "shows the system administrator dashboard" do
        sign_in current_user
        visit dashboard_path
        click_on "Administration"
        expect(page).to have_button("Import Mediaflux Projects")
        expect(page).to have_content("Approved Projects")
        expect(page).to have_content "project 111"
        expect(page).to have_content "project 444"
      end

      it "renders the 'Administration' tab" do
        sign_in current_user
        visit dashboard_path
        expect(page).to have_content "Administration"
      end
    end

    context "flash message" do
      let(:non_admin_user) { FactoryBot.create(:user) }
      it "shows the flash message" do
        sign_in non_admin_user
        visit "/projects"
        expect(page).to have_content("Access Denied")
      end
    end
  end
end
