# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Edit Page Roles Validation", type: :system, connect_to_mediaflux: true, js: true do
  # TODO: - When the sponsors have access to write in the system we should remove trainer from here
  # let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session, trainer: true) }
  let(:data_manager) { FactoryBot.create(:data_manager, uid: "pul987", mediaflux_session: SystemUser.mediaflux_session) }
  let(:system_admin) { FactoryBot.create(:sysadmin, uid: "pul777", mediaflux_session: SystemUser.mediaflux_session) }
  let(:superuser) { FactoryBot.create(:superuser, uid: "pul999", mediaflux_session: SystemUser.mediaflux_session) }
  let(:read_only) { FactoryBot.create :user }
  let(:read_write) { FactoryBot.create :user }
  before do
    sign_in sponsor_user
    Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))

    # make sure the users exist before the page loads
    data_manager
    read_only
    read_write
    system_admin
  end

  context "Super Users can input a data sponsor and project id" do
    let(:superuser) { FactoryBot.create(:superuser) }
    let(:sponsor_user) { User.find_by(uid: project.metadata_model.data_sponsor) }
    let(:project) { FactoryBot.create(:project) }
    it "only allows the super user to set the Data Sponsor" do
      sponsor_user # make sure the user is available to the form
      project.metadata_model.status = Project::APPROVED_STATUS
      project.save!
      sign_in superuser
      visit "/projects/#{project.id}/edit"
      fill_in "data_sponsor", with: sponsor_user.uid
      fill_in "project_id", with: "999-abc"
      page.find("body").click
      click_on "Submit"
      visit "/projects/#{project.id}/details"
      expect(page.find(:css, "#data_sponsor").text).to eq sponsor_user.display_name
      expect(page.find(:css, "#project_id").text).to eq "999-abc"
    end
  end

  context "Data Sponsors are the only people who can assign Data Managers" do
    let(:data_manager) { FactoryBot.create(:data_manager) }
    let(:project) { FactoryBot.create(:project, data_manager: data_manager.uid) }
    let(:sponsor_user) { User.find_by(uid: project.metadata_model.data_sponsor) }
    let!(:new_data_manager) { FactoryBot.create(:data_manager) }
    it "allows a Data Sponsor to assign a Data Manager" do
      sign_in sponsor_user
      sponsor_user["eligible_sponsor"] = true
      sponsor_user.save!
      project.metadata_model.status = Project::APPROVED_STATUS
      project.save!
      visit "/projects/#{project.id}/edit"
      fill_in "data_manager", with: new_data_manager.uid
      page.find("body").click
      click_on "Submit"
      visit "/projects/#{project.id}/details"
      expect(page.find(:css, "#data_manager").text).to eq new_data_manager.display_name
    end
    it "does not allow anyone else to assign a Data Manager" do
      sign_in data_manager
      data_manager["eligible_sponsor"] = true
      data_manager.save
      project.metadata_model.status = Project::APPROVED_STATUS
      project.save!
      visit "/projects/#{project.id}/edit"
      expect(page.find(:css, "#non-editable-data-sponsor").text).to eq sponsor_user.uid
      expect(page.find(:css, "#non-editable-data-manager").text).to eq data_manager.uid
    end
  end

  context "A user can be both a Data Sponsor and a Data Manager" do
    let(:user) { FactoryBot.create(:sponsor_and_data_manager) }
    let(:project) { FactoryBot.create(:project, data_sponsor: user.uid, data_manager: user.uid) }
    it "allows for a user to be both a Data Sponsor and a Data Manager" do
      expect(project.metadata_json["data_sponsor"]).to eq user.uid
      expect(project.metadata_json["data_manager"]).to eq user.uid
    end
  end

  context "Data Sponsors and Data Managers can assign Data Users" do
    let(:project) { FactoryBot.create(:project, status: Project::APPROVED_STATUS) }
    let(:sponsor_user) { User.find_by(uid: project.metadata_json["data_sponsor"]) }
    let(:data_manager) { User.find_by(uid: project.metadata_json["data_manager"]) }
    let!(:ro_data_user) { FactoryBot.create(:user) }
    let!(:rw_data_user) { FactoryBot.create(:user) }
    it "allows a Data Sponsor to assign a Data User" do
      sign_in sponsor_user
      visit "/projects/#{project.id}/edit"
      click_on "Add User(s)"
      fill_in_and_out "data-user-uid-to-add", with: ro_data_user.uid
      click_on "Save changes"
      click_on "Submit"
      visit "/projects/#{project.id}/details"
      expect(page).to have_content "#{ro_data_user.display_name} (read only)"
    end
    it "allows a Data Manager to assign a Data User" do
      sign_in data_manager
      visit "/projects/#{project.id}/edit"
      click_on "Add User(s)"
      fill_in_and_out "data-user-uid-to-add", with: ro_data_user.uid
      click_on "Save changes"
      click_on "Submit"
      visit "/projects/#{project.id}/details"
      expect(page).to have_content "#{ro_data_user.display_name} (read only)"
    end
  end
end
