# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Create new project", connect_to_mediaflux: true, js: true do
  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user) }

    before do
      sign_in current_user
      visit dashboard_path
    end

    it "shows the welcome message and does not show the create button" do
      expect(page).to have_content("Welcome, #{current_user.given_name}!")
      expect(page).not_to have_content "Create new project"
    end

    context "the user signed in is an eligible sponsor" do
      let(:current_user) { FactoryBot.create(:project_sponsor) }

      it "shows the welcome message and does not show the create button" do
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        expect(page).not_to have_content "Create new project"
      end
    end

    context "the user signed in is an eligible data manager" do
      let(:current_user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session, eligible_manager: true) }

      it "shows the welcome message and does not show the create button" do
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        expect(page).not_to have_content "Create new project"
      end
    end

    context "for tester-trainers" do
      let(:current_user) { FactoryBot.create(:trainer) }
      it "shows the emulation bar and shows the Create new button when the trainer is a data sponsor" do
        expect(page).to have_select("emulation_menu")
        expect(page).not_to have_content "Create new project"
        select "Data Sponsor", from: "emulation_menu"
        expect(page).to have_content "Create new project"
      end

      context "in production" do
        before do
          allow(Rails.env).to receive(:production?).and_return true
          visit dashboard_path
        end

        it "does not show the emulation menu or the create new button" do
          expect(page).not_to have_select("emulation_menu")
          expect(page).not_to have_content "Create new project"
        end
      end
    end

    context "with the sysadmin role" do
      let(:current_user) { FactoryBot.create(:sysadmin) }

      it "shows the Create new button" do
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        expect(page).to have_content "Create new project"
      end
    end

    context "with the superuser role" do
      let(:current_user) { FactoryBot.create(:superuser) }

      it "shows the Create new button" do
        expect(page).to have_content("Welcome, #{current_user.given_name}!")
        expect(page).to have_content "Create new project"
      end
    end
  end
end
