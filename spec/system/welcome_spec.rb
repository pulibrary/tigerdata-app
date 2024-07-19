# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WelcomeController", stub_mediaflux: true, js: true do
  #TODO: refactor the stub_mediaflux to connect to the real mediaflux
    #     visiting the welcome page "/" is posting to mediaflux
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "Welcome to TigerData"
      expect(page).to have_content "Log In"
      expect(page).to have_link "Accessibility", href: "https://accessibility.princeton.edu/help"
    end

    it "forwards to login page" do
      project = FactoryBot.create(:project)
      visit project_path(project)
      expect(page).to have_content "You need to sign in or sign up before continuing."
    end

    it "binds the Mediaflux status component to the DOM" do
      visit "/"
      expect(page).to have_content "Mediaflux Status"
      expect(page).to have_css ".mediaflux-status.inactive"
    end

    context "when the Mediaflux API returns a valid server response with a superuser account" do
      let(:superuser) { FactoryBot.create(:superuser) }

      before do
        superuser
        visit "/"
      end

      it "defaults to the inactive state for the Mediaflux status component" do
        expect(page).to have_content "Mediaflux Status"
        sleep(1)
        expect(page).to have_css ".mediaflux-status.active"
      end
    end
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123") }
    let(:other_user) { FactoryBot.create(:user, uid: "zz123") }
    let(:no_projects_user) { FactoryBot.create(:user, uid: "qw999") }
    let(:no_projects_sponsor) { FactoryBot.create(:project_sponsor, uid: "gg717") }
    before do
      FactoryBot.create(:project, data_sponsor: current_user.uid, data_manager: other_user.uid, title: "project 111")
      FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: current_user.uid, title: "project 222")
      FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: other_user.uid, data_user_read_only: [current_user.uid], title: "project 333")
      FactoryBot.create(:project, data_sponsor: other_user.uid, data_manager: other_user.uid, title: "project 444")
    end

    context "current user dashboard" do
      it "shows the 'Log Out' button" do
        sign_in current_user
        visit "/"
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        expect(page).not_to have_content "Please log in"
        expect(page).to have_content "Log Out"
      end

      it "shows the Mediflux version on the home page for a logged in user", connect_to_mediaflux: true do
        sign_in current_user
        visit "/"
        sleep(1)
        expect(page).to have_content "Mediaflux: 4.16.032"
      end

      it "shows the projects based on the user's role" do
        sign_in current_user
        visit "/"
        expect(page).not_to have_content "Sponsored by Me"
        expect(page).not_to have_content "project 111"
        expect(page).not_to have_content "Managed by Me"
        expect(page).not_to have_content "project 222"
        expect(page).to have_content "Shared with Me"
        expect(page).to have_content "project 333"
        # The current user has no access to this project so we don't expect to see it
        expect(page).not_to have_content "project 444"
      end

      context "the user signed in is an eligible sponsor" do
        it "shows the projects based on the user's role" do
          current_user.update(eligible_sponsor: true)

          sign_in current_user
          visit "/"
          expect(page).to have_content "Sponsored by Me"
          expect(page).to have_content "project 111"
          expect(page).not_to have_content "Managed by Me"
          expect(page).not_to have_content "project 222"
          expect(page).to have_content "Shared with Me"
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
          expect(page).not_to have_content "Sponsored by Me"
          expect(page).not_to have_content "project 111"
          expect(page).to have_content "Managed by Me"
          expect(page).to have_content "project 222"
          expect(page).to have_content "Shared with Me"
          expect(page).to have_content "project 333"
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
    end

    context "for a user without any projects" do
      it "shows the 'Log Out' button" do
        sign_in no_projects_user
        visit "/"
        expect(page).not_to have_content "Please log in"
        expect(page).to have_content "Log Out"
      end

      context "if the user is not a sponsor" do
        it "does not show any projects" do
          sign_in no_projects_user
          visit "/"
          expect(page).to have_content("Welcome, #{no_projects_user.given_name}!")
          expect(page).not_to have_content("Sponsored by Me")
          expect(page).to have_content("Recent Activity")
        end
      end

      context "if the user is a sponsor" do
        it "shows the New Project button and shows the Sponsored by Me heading" do
          sign_in no_projects_sponsor
          visit "/"
          expect(page).to have_content("Sponsored by Me")
          expect(page).to have_content("Recent Activity")
          expect(page).to have_selector(:link_or_button, "New Project")
        end
      end
    end

    context "with the superuser role" do
      let(:current_user) { FactoryBot.create(:superuser, uid: "xxx999") }

      it "shows the 'New Project' button" do
        sign_in current_user
        visit "/"
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        expect(page).not_to have_content "Please log in"
        expect(page).to have_content "New Project"
      end

      it "shows the system administrator dashboard" do
        sign_in current_user
        visit "/"
        expect(page).to have_content("Pending Projects")
        expect(page).to have_content("Approved Projects")
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
        expect(page).to have_content("Sponsored by Me")
        expect(page).not_to have_content("Managed by Me")
        expect(page).to have_content("Shared with Me")
      end
      it "displays sponsored projects when emulating a data manager" do
        sign_in current_user
        current_user.trainer = true
        current_user.save!
        visit "/"
        select "Data Manager", from: "emulation_menu"
        expect(page).not_to have_content("Sponsored by Me")
        expect(page).to have_content("Managed by Me")
        expect(page).to have_content("Shared with Me")
        expect(page).to be_axe_clean
          .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
          .skipping(:'color-contrast') # false positives
          .excluding(".tt-hint") # Issue is in typeahead.js library
      end
    end
  end
end
