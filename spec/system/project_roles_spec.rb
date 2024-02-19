# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Edit Page Roles Validation", type: :system do
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, uid: "pul123") }
  let(:data_manager) { FactoryBot.create(:data_manager, uid: "pul987") }
  let(:read_only) { FactoryBot.create :user }
  let(:read_write) { FactoryBot.create :user }
  before do
    sign_in sponsor_user

    # make sure the users exist before the page loads
    data_manager
    read_only
    read_write
  end

  it "allows the user fill in only valid users for roles" do
    sign_in sponsor_user
    visit "/"
    click_on "New Project"

    # Data Sponsor is not editable. It can only be the user who is initiating this request.
    expect(page.find("#non-editable-data-sponsor").text).to eq sponsor_user.uid
    fill_in "data_manager", with: "xxx"
    page.find("body").click
    expect(page.find("input[value=Submit]")).to be_disabled
    expect(page.find("#data_manager").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "data_manager", with: ""
    expect(page.find("input[value=Submit]")).to be_disabled
    expect(page.find("#data_manager").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "data_manager", with: data_manager.uid
    page.find("body").click
    click_on "Submit"
    expect(page.find("#data_manager").native.attribute("validationMessage")).to eq ""

    # clicking on Save because once the button is disabled it does not get reenabled until after the user clicks out of the text box
    fill_in "ro-user-uid-to-add", with: "xxx"
    page.find("body").click
    expect(page.find("#btn-add-ro-user")).to be_disabled
    expect(page.find("#ro-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "ro-user-uid-to-add", with: ""
    page.find("body").click
    expect(page.find("#btn-add-ro-user")).to be_disabled
    expect(page.find("#ro-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "ro-user-uid-to-add", with: read_only.uid
    page.find("body").click
    click_on "btn-add-ro-user"
    expect(page.find("#ro-user-uid-to-add").native.attribute("validationMessage")).to eq ""

    # clicking on Save because once the button is disabled it does not get reenabled until after the user clicks out of the text box
    fill_in "rw-user-uid-to-add", with: "xxx"
    page.find("body").click
    expect(page.find("#btn-add-rw-user")).to be_disabled
    expect(page.find("#rw-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "rw-user-uid-to-add", with: ""
    page.find("body").click
    expect(page.find("#btn-add-rw-user")).to be_disabled
    expect(page.find("#rw-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "rw-user-uid-to-add", with: read_write.uid
    click_on "Submit"
    click_on "btn-add-rw-user"
    expect(page.find("#rw-user-uid-to-add").native.attribute("validationMessage")).to eq ""

    fill_in "directory", with: "test_project"
    fill_in "title", with: "My test project"
    expect(page).to have_content("Project Directory: /td-test-001/")
    expect do
      expect(page.find_all("input:invalid").count).to eq(0)
      click_on "Submit"
      # For some reason the above click on submit sometimes does not submit the form
      #  even though the inputs are all valid, so try it again...
      if page.find_all("#btn-add-rw-user").count > 0
        click_on "Submit"
      end
    end.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1).times
    expect(page).to have_content "New Project Request Received"
    click_on "Return to Dashboard"
    expect(page).to have_content("Welcome")
    click_on("My test project")
    expect(page).to have_content("This project has not been saved to Mediaflux")
    expect(page).to have_content("My test project (pending)")
    expect(page).to have_content("My test project (#{::Project::PENDING_STATUS})")
    expect(page).to have_content(read_only.given_name)
    expect(page).to have_content(read_only.display_name)
    expect(page).to have_content(read_only.family_name)
    expect(page).to have_content(read_write.given_name)
    expect(page).to have_content(read_write.display_name)
    expect(page).to have_content(read_write.family_name)
  end

  context "Data Sponsors and superusers are the only ones who can request a new project" do
    let(:superuser) { FactoryBot.create(:superuser) }
    it "allows Data Sponsors to request a new project" do
      sign_in sponsor_user
      visit "/"
      click_on "New Project"
      expect(page).to have_content "New Project Request"
    end
    it "allows superusers to request a new project" do
      sign_in superuser
      visit "/"
      click_on "New Project"
      expect(page).to have_content "New Project Request"
    end
    it "does not give anyone else the New Project button" do
      sign_in data_manager
      visit "/"
      expect(page).not_to have_content "New Project"
    end
    it "only allows the Data Sponsor to load the New Projects page" do
      sign_in data_manager
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
  context "Data Sponsors are the only people who can assign Data Managers" do
    let(:project) { FactoryBot.create(:project) }
    let(:sponsor_user) { User.find_by(uid: project.metadata_json["data_sponsor"]) }
    let(:data_manager) { User.find_by(uid: project.metadata_json["data_manager"]) }
    let!(:new_data_manager) { FactoryBot.create(:data_manager) }
    it "allows a Data Sponsor to assign a Data Manager" do
      sign_in sponsor_user
      visit "/projects/#{project.id}/edit"
      fill_in "data_manager", with: new_data_manager.uid
      page.find("body").click
      click_on "Submit"
      expect(page.find(:css, "#data_manager").text).to eq new_data_manager.display_name
    end
    it "does not allow anyone else to assign a Data Manager" do
      sign_in data_manager
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
    let(:project) { FactoryBot.create(:project) }
    let(:sponsor_user) { User.find_by(uid: project.metadata_json["data_sponsor"]) }
    let(:data_manager) { User.find_by(uid: project.metadata_json["data_manager"]) }
    let!(:ro_data_user) { FactoryBot.create(:user) }
    let!(:rw_data_user) { FactoryBot.create(:user) }
    it "allows a Data Sponsor to assign a Data User" do
      sign_in sponsor_user
      visit "/projects/#{project.id}/edit"
      fill_in "ro-user-uid-to-add", with: ro_data_user.uid
      page.find("body").click
      find(:css, "#btn-add-ro-user").click
      page.find("body").click
      fill_in "rw-user-uid-to-add", with: rw_data_user.uid
      page.find("body").click
      find(:css, "#btn-add-rw-user").click
      page.find("body").click
      click_on "Submit"
      expect(page).to have_content "#{ro_data_user.display_name} (read only)"
      expect(page).to have_content rw_data_user.display_name
    end
    it "allows a Data Manager to assign a Data User" do
      sign_in data_manager
      visit "/projects/#{project.id}/edit"
      fill_in "ro-user-uid-to-add", with: ro_data_user.uid
      page.find("body").click
      find(:css, "#btn-add-ro-user").click
      page.find("body").click
      fill_in "rw-user-uid-to-add", with: rw_data_user.uid
      page.find("body").click
      find(:css, "#btn-add-rw-user").click
      page.find("body").click
      click_on "Submit"
      expect(page).to have_content "#{ro_data_user.display_name} (read only)"
      expect(page).to have_content rw_data_user.display_name
    end
  end
end
