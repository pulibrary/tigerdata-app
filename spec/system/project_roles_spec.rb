# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Edit Page Roles Validation", type: :system, connect_to_mediaflux: true, js: true do
  # TODO: - When the sponsors have access to write in the system we should remove trainer from here
  # let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
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

  it "allows the user fill in only valid users for roles" do
    sign_in sponsor_user
    visit "/"
    click_on "Create new project"

    # Check data manager validations (invalid value, empty value, valid value)
    expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
    fill_in_and_out "data_manager", with: "xxx"
    expect(page.find("#data_manager_error").text).to eq "Invalid value entered"
    expect(page.find("button[value=Submit]")).to be_disabled
    fill_in_and_out "data_manager", with: ""
    expect(page.find("button[value=Submit]")).to be_disabled
    fill_in_and_out "data_manager", with: ""
    expect(page.find("#data_manager_error").text).to eq "This field is required"
    fill_in_and_out "data_manager", with: data_manager.uid
    expect(page.find("#data_manager_error", visible: false).text).to eq ""
    expect(page.find("button[value=Submit]").disabled?).to be false

    # Adds a data user (read-only)
    click_on "Add User(s)"
    fill_in_and_out "data-user-uid-to-add", with: read_only.uid
    click_on "Save changes"

    page.find("#departments").find(:xpath, "option[3]").select_option

    fill_in "project_directory", with: "test_project"
    fill_in "title", with: "My test project"
    expect(page).to have_content("/td-test-001/")
    expect(page.find_all("input:invalid").count).to eq(0)
    expect do
      click_button("Submit")
    end.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1).times
    expect(page).to have_content "New Project Request Received"
    click_on "Return to Dashboard"
    expect(page).to have_content("Welcome")
    find(:xpath, "//a[text()='My test project']").click
    click_on "Details"
    expect(page).to have_content("This project has not been saved to Mediaflux")
    expect(page).to have_content(read_only.display_name + " (read only)")
  end

  context "Data Sponsors and superusers are the only ones who can request a new project" do
    let(:superuser) { FactoryBot.create(:superuser, mediaflux_session: SystemUser.mediaflux_session) }
    it "allows Data Sponsors to request a new project" do
      sign_in sponsor_user
      visit "/"
      click_on "Create new project"
      expect(page).to have_content "New Project Request"
    end
    it "allows superusers to request a new project" do
      sign_in superuser
      visit "/"
      click_on "Create new project"
      expect(page).to have_content "New Project Request"
    end
    it "does not give the data manager the New Project button" do
      sign_in data_manager
      visit "/"
      expect(page).not_to have_content "Create new project"
    end
    it "only allows the Data Sponsor to load the New Projects page" do
      sign_in data_manager
      visit "/projects/new"
      expect(current_path).to eq root_path
    end
    it "does not give the sytem admin New Project button" do
      sign_in system_admin
      visit "/"
      expect(page).to have_content "Create new project"
    end
    it "does not allow the system administrato to load New Projects page" do
      sign_in system_admin
      visit "/projects/new"
      expect(current_path).to eq root_path
    end
  end
  context "The Data Sponsor who initiates the request is automatically assigned as the Data Sponsor for that project" do
    let(:data_sponsor) { FactoryBot.create(:project_sponsor) }
    it "only allows the user who initiated the request as the Data Sponsor" do
      sign_in data_sponsor
      visit "/projects/new"
      expect(page.find("#non-editable-data-sponsor").text).to eq data_sponsor.uid
    end
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
    let(:project) { FactoryBot.create(:project) }
    let(:sponsor_user) { User.find_by(uid: project.metadata_model.data_sponsor) }
    let(:data_manager) { User.find_by(uid: project.metadata_model.data_manager) }
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
    let(:user) { FactoryBot.create(:project_sponsor_and_data_manager) }
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

  context "only system admins and super users can approve a project" do
    let(:project) { FactoryBot.create(:project, status: Project::PENDING_STATUS) }

    it "allows a system admins user to approve the project" do
      sign_in system_admin
      visit project_approve_path(project)
      click_on "Approve"
      expect(page).to have_content "Metadata Highlights"
    end

    it "allows a super user to approve the project" do
      sign_in superuser
      visit project_approve_path(project)
      click_on "Approve"
      expect(page).to have_content "Metadata Highlights"
    end

    it "does not allow a data sponsor to approve the project" do
      sign_in sponsor_user
      visit project_approve_path(project)
      expect(page).not_to have_content "Approve this project by appending a mediaflux id"
    end

    it "does not allow a data manager to approve the project" do
      sign_in data_manager
      visit project_approve_path(project)
      expect(page).not_to have_content "Approve this project by appending a mediaflux id"
    end

    it "does not allow a data user to approve the project" do
      sign_in read_only
      visit project_approve_path(project)
      expect(page).not_to have_content "Approve this project by appending a mediaflux id"
    end
  end
end
