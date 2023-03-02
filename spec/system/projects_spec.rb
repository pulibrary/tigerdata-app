# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectsController do
  context "authenticated and authorized user" do
    uid = "knight"
    let(:user) { User.find_by(uid: uid) }
    before do
      sign_in user
    end
    ["Data User", "Data Manager", "Data Sponsor"].each do |role|
      it "allows navigation to seeded #{role} page for seeded user #{uid}" do
        visit "/"
        click_on role
        click_on "Sample project with #{uid} as #{role}"
        expect(page).to have_content("Project: Sample project with #{uid} as #{role}")
      end
    end
  end
end
