# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WelcomeController" do
  it "visits the root", js: true do
    visit "/"

    expect(page).to have_content "Welcome"
    click_on "Test jQuery"
    expect(page).to have_content "jQuery works!"
  end
end
