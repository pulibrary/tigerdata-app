# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizations", stub_mediaflux: true do
  let(:user) { FactoryBot.create(:user, uid: "pul123") }
  before do
    sign_in user
  end
  it "shows the organizations" do
    visit "/"
    click_on "Organizations"
    expect(page).to have_content("Princeton Physics Plasma Lab")
  end
end
