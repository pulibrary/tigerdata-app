# frozen_string_literal: true

require "rails_helper"

describe "flipflop", type: :system, js: true do
  it "flip flop doesn't show for un logged in user" do
    visit "/flipflop"
    expect(page).to have_content("You need to sign in")
  end

  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123") }

    before do
      sign_in current_user
    end

    it "flip flop doesn't show for any user" do
      visit "/flipflop"
      expect(page).not_to have_content("Alternate mediaflux")
    end
  end

  context "sponsor user" do
    let(:current_user) { FactoryBot.create(:project_sponsor, uid: "pul123") }

    before do
      sign_in current_user
    end

    it "flip flop doesn't show for any user" do
      visit "/flipflop"
      expect(page).not_to have_content("Alternate mediaflux")
    end
  end

  context "super user" do
    let(:current_user) { FactoryBot.create(:superuser, uid: "pul123") }

    before do
      sign_in current_user
    end

    it "flip flop doesn't show for any user" do
      visit "/flipflop"
      expect(page).to have_content("Alternate mediaflux")
    end
  end

  context "sysadmin user" do
    let(:current_user) { FactoryBot.create(:sysadmin, uid: "pul123") }

    before do
      sign_in current_user
    end

    it "flip flop doesn't show for any user" do
      visit "/flipflop"
      expect(page).to have_content("Alternate mediaflux")
    end
  end
end
