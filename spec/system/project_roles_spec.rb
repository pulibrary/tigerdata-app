# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Edit Page Roles Validation", type: :system do
  let(:sponsor_user) { FactoryBot.create(:user, uid: "pul123") }
  let(:data_manager) { FactoryBot.create(:user, uid: "pul987") }
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
    expect(page.find("#data_sponsor").value).to eq sponsor_user.uid
    fill_in "data_sponsor", with: ""
    expect(page.find("input[value=Submit]")).to be_disabled
    expect(page.find("#data_sponsor").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "data_sponsor", with: "xxx"
    expect(page.find("input[value=Submit]")).to be_disabled
    expect(page.find("#data_sponsor").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "data_sponsor", with: sponsor_user.uid
    page.find("body").click
    click_on "Submit"
    expect(page.find("#data_sponsor").native.attribute("validationMessage")).to eq ""

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

  context "Data Sponsors are the only ones who can request a new project" do
    xit "allows Data Sponsors to request a new project" do
    end
    xit "does not allow anyone else to request a new project" do
    end
  end
  context "The Data Sponsor who initiates the request is automatically assigned as the Data Sponsor for that project" do
    xit "assigns the user who initiated the request as the Data Sponsor" do
    end
    xit "does not assign anyone else as the Data Sponsor" do
    end
  end
  context "Data Sponsors are the only people who can assign Data Managers" do
    xit "allows a Data Sponsor to assign a Data Manager" do
    end
    xit "does not allow anyone else to assign a Data Manager" do
    end
    xit "allows for a user to be both a Data Sponsor and a Data Manager" do
    end
    xit "does not allow a Data Manager to edit a Data Manager role" do
    end
  end
  context "Data Sponsors and Data Managers can assign Data Users" do
    xit "allows a Data Sponsor to assign a Data User" do
    end
    xit "allows a Data Manager to assign a Data User" do
    end
    xit "does not allow a Data User to assign a Data User" do
    end
  end
end
