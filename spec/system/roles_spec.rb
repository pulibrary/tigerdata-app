# frozen_string_literal: true

require "rails_helper"

RSpec.describe RolesController do
  context "authenticated user" do
    let(:user) { FactoryBot.create(:user, uid: "pul123") }
    before do
      sign_in user
    end
    it "shows a list of Roles" do
      visit "/"
      click_on "Roles"
      expect(page).to have_content "TigerData Roles"
      expect(page).to have_content "Data Sponsor"
      expect(page).to have_content "The person bearing primary responsibility for a project"
    end
  end
end
