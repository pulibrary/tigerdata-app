# frozen_string_literal: true
require "rails_helper"

describe "home", type: :system do
  context "when on the hompage" do
    it "shows the footer" do
      visit "/"
      expect(page).to have_selector("#footer")
    end
  end
end
