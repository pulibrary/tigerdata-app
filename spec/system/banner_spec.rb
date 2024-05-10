# frozen_string_literal: true

require "rails_helper"

describe "Website banner", type: :system, js: true do
  it "has the banner on the homepage" do
    visit "/"
    expect(page).to have_css "#banner"
  end
end
