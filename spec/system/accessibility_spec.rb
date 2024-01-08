# frozen_string_literal: true
require "rails_helper"

describe "application accessibility", type: :system, js: true, stub_mediaflux: true do
  context "when browsing the homepage" do
    it "complies with WCAG 2.0 AA and Section 508" do
      visit "/"
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
        .skipping(:'color-contrast') # false positives
        .excluding(".tt-hint") # Issue is in typeahead.js library
    end
  end

  context "when browsing the organizations page" do
    it "complies with WCAG 2.0 AA and Section 508" do
      visit "/organizations"
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
        .skipping(:'color-contrast')
    end
  end

  # We are not connecting to MediaFlux anymore
  # context "when browsing media_flux" do
  #   let(:sponsor_user) { FactoryBot.create(:user, uid: "pul123") }
  #   it "complies with WCAG 2.0 AA and Section 508" do
  #     sign_in sponsor_user
  #     visit "/mediaflux_info"
  #     expect(page).to be_axe_clean
  #       .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
  #       .skipping(:'color-contrast')
  #   end
  # end

  context "when browsing the help page" do
    it "complies with WCAG 2.0 AA and Section 508" do
      visit "/help"
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
        .skipping(:'color-contrast')
    end
  end
end
