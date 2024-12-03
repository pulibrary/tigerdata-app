# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WelcomeController", connect_to_mediaflux: true, js: true do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "Welcome to TigerData"
      expect(page).to have_content "Log in"
      expect(page).to have_link "Accessibility", href: "https://accessibility.princeton.edu/help"
    end

    it "forwards to login page" do
      project = FactoryBot.create(:project)
      visit project_path(project)
      expect(page).to have_content "You need to sign in or sign up before continuing."
    end
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
    let(:other_user) { FactoryBot.create(:user, uid: "zz123") }
    let(:no_projects_user) { FactoryBot.create(:user, uid: "qw999") }
    let(:no_projects_sponsor) { FactoryBot.create(:project_sponsor, uid: "gg717") }
    let(:docker_response) { "Mediaflux: 4.16.071" }
    let(:ansible_response) { "Mediaflux: 4.16.047" }

    before do
      FactoryBot.create(:project, data_sponsor: current_user.uid, data_manager: other_user.uid, title: "project 111")
      FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: current_user.uid, title: "project 222")
      FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: other_user.uid, data_user_read_only: [current_user.uid], title: "project 333")
      FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: other_user.uid, title: "project 444")
    end

    context "current user dashboard" do
      it "shows the welcome message and 'Log out' button" do
        sign_in current_user
        visit "/"

        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        click_link current_user.uid.to_s
        expect(page).to have_content "Log out"
      end

      it "shows the Mediflux version on the home page for a logged in user" do
        sign_in current_user
        visit "/"
        sleep(1)
        expect(page).to have_content(docker_response).or have_content(ansible_response)
      end

      it "shows the projects based on the user's role" do
        sign_in current_user
        visit "/"
        expect(page).not_to have_content "Sponsor"
        expect(page).not_to have_content "project 111"
        expect(page).not_to have_content "Data Manager"
        expect(page).not_to have_content "project 222"
        expect(page).to have_content "Data User"
        expect(page).to have_content "project 333"
        expect(page).to have_content "Activity"
        # The current user has no access to this project so we don't expect to see it
        expect(page).not_to have_content "project 444"
      end

      context "the user signed in is an eligible sponsor" do
        it "shows the projects based on the user's role" do
          current_user.update(eligible_sponsor: true)

          sign_in current_user
          visit "/"
          expect(page).to have_content "Sponsor"
          expect(page).to have_content "project 111"
          expect(page).to have_content "Activity"
          expect(page).not_to have_content "Data Manager"
          expect(page).not_to have_content "project 222"
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
          visit "/"
          expect(page).not_to have_content "Sponsor"
          expect(page).not_to have_content "project 111"
          expect(page).to have_content "Data Manager"
          expect(page).to have_content "project 222"
          expect(page).to have_content "Data User"
          expect(page).to have_content "project 333"
          expect(page).to have_content "Activity"
          # The current user has no access to this project so we don't expect to see it
          expect(page).not_to have_content "project 444"
        end
      end

      it "allows for navigation back to user dashboard when clicking logo" do
        sign_in current_user
        visit "/projects"
        expect(page).to have_content "project 111"
        page.find(:css, "#logo").click
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
      end

      it "paginates the projects; 8 per page" do
        projects = (1..16).map { FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: other_user.uid, data_user_read_only: [current_user.uid]) }
        sign_in current_user
        visit "/"
        expect(page).to have_content("8 out of 17 shown")
        find("a.paginate_button", text: 2).click
        expect(page).to have_content(projects[8].title)
        find("a.paginate_button", text: 3).click
        expect(page).to have_content(projects.last.title)
        find("a.paginate_button", text: "<").click
        expect(page).to have_content(projects[14].title)
        find("a.paginate_button", text: "<").click
        expect(page).to have_content(projects.first.title)
      end
    end

    context "for a user without any projects" do
      it "shows the 'Log out' button" do
        sign_in no_projects_user
        visit "/"
        expect(page).to have_content("Welcome, #{no_projects_user.given_name}!")
        click_link no_projects_user.uid.to_s
        expect(page).to have_content "Log out"
      end
    end

    context "with the superuser role" do
      let(:current_user) { FactoryBot.create(:superuser, uid: "xxx999") }

      it "shows the 'New Project' button" do
        sign_in current_user
        visit "/"
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        expect(page).not_to have_content "Please log in"
        expect(page).to have_content "Create new project"
      end

      it "shows the system administrator dashboard" do
        sign_in current_user
        visit "/"
        visit "/"
        click_on "Administration"
        expect(page).to have_content("Pending Projects")
        expect(page).to have_content("Approved Projects")
        expect(page).to have_content("Activity")
      end
    end

    context "for tester-trainers" do
      it "shows the emulation bar" do
        sign_in current_user
        current_user.trainer = true
        current_user.save!
        visit "/"
        expect(page).to have_select("emulation_menu")
      end
      it "displays sponsored projects when emulating a data sponsor" do
        sign_in current_user
        current_user.trainer = true
        current_user.save!
        visit "/"
        select "Data Sponsor", from: "emulation_menu"
        within("#projects-listing") do
          expect(page).to have_content("Sponsor")
          expect(page).not_to have_content("Data Manager")
          expect(page).to have_content("Data User")
        end
        expect(page).to have_content("Activity")
      end
      it "displays sponsored projects when emulating a data manager" do
        sign_in current_user
        current_user.trainer = true
        current_user.save!
        visit "/"
        select "Data Manager", from: "emulation_menu"
        within("#projects-listing") do
          expect(page).not_to have_content("Sponsor")
          expect(page).to have_content("Data Manager")
          expect(page).to have_content("Data User")
        end
        expect(page).to have_content("Activity")
        expect(page).to be_axe_clean
          .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
          .skipping(:'color-contrast') # false positives
          .excluding(".tt-hint") # Issue is in typeahead.js library
      end
    end

    context "with the sysadmin role" do
      let(:current_user) { FactoryBot.create(:sysadmin, uid: "xxx999") }

      it "does not show the 'New Project' button" do
        sign_in current_user
        visit "/"
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        expect(page).not_to have_content "Please log in"
        expect(page).not_to have_content "Create new project"
      end

      it "shows the system administrator dashboard" do
        sign_in current_user
        visit "/"
        click_on "Administration"
        expect(page).to have_content("Pending Projects")
        expect(page).to have_content("Approved Projects")
        expect(page).to have_content("Activity")
      end
    end
  end
end
