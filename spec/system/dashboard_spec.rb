# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DashboardController" do
  context "authenticated user, but unauthorized" do
    let(:user) { FactoryBot.create(:user, uid: "pul123") }
    before do
      sign_in user
    end
    it "denies access" do
      visit "/dashboards/data-user"
      expect(page).to have_content "Access Denied"
    end
  end

  context "authenticated and authorized user" do
    let(:user) { FactoryBot.create(:user, uid: "knight") }
    before do
      sign_in user
    end
    it "allows access" do
      visit "/"
      click_on "Data User"
      expect(page).to have_content "Dashboard: Data User"
    end
  end

  context "non existant dashboard access denied" do
    let(:user) { FactoryBot.create(:user, uid: "knight") }
    before do
      sign_in user
    end
    it "denies access" do
      visit "/dashboards/xyz"
      expect(page).to have_content "Access Denied"
    end
  end
end
