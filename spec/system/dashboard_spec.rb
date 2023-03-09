# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WelcomeController" do
  context "authenticated user, but unauthorized", stub_mediaflux: true do
    let(:user) { FactoryBot.create(:user, uid: "pul123") }
    before do
      sign_in user
    end
    it "denies access" do
      visit "/dashboards/a"
      expect(page).to have_content "Access Denied"
    end
  end

  context "authenticated and authorized user", stub_mediaflux: true do
    let(:user) { FactoryBot.create(:user, uid: "knight") }
    before do
      sign_in user
    end
    it "allows access" do
      visit "/dashboards/a"
      expect(page).to have_content "These dashboards are available"
    end
  end

  context "non existant dashboard access denied", stub_mediaflux: true do
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
