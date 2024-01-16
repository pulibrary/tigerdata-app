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
    click_on "Submit"
    expect(page.find("#data_sponsor").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "data_sponsor", with: "xxx"
    click_on "Submit"
    expect(page.find("#data_sponsor").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "data_sponsor", with: sponsor_user.uid
    click_on "Submit"
    expect(page.find("#data_sponsor").native.attribute("validationMessage")).to eq ""

    fill_in "data_manager", with: "xxx"
    click_on "Submit"
    expect(page.find("#data_manager").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "data_manager", with: ""
    click_on "Submit"
    expect(page.find("#data_manager").native.attribute("validationMessage")).to eq "Please select a valid value."
    fill_in "data_manager", with: data_manager.uid
    click_on "Submit"
    expect(page.find("#data_manager").native.attribute("validationMessage")).to eq ""

    # clicking on Save becuase once the button is disabled it does not get reenabled until after the user clicks out of the text box
    fill_in "ro-user-uid-to-add", with: "xxx"
    click_on "Submit"
    expect(page.find("#ro-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."
    expect(page.find("#btn-add-ro-user")).to be_disabled
    fill_in "ro-user-uid-to-add", with: ""
    click_on "Submit"
    expect(page.find("#ro-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."
    expect(page.find("#btn-add-ro-user")).to be_disabled
    fill_in "ro-user-uid-to-add", with: read_only.uid
    click_on "Submit"
    click_on "btn-add-ro-user"
    expect(page.find("#ro-user-uid-to-add").native.attribute("validationMessage")).to eq ""

    # clicking on Save becuase once the button is disabled it does not get reenabled until after the user clicks out of the text box
    fill_in "rw-user-uid-to-add", with: "xxx"
    click_on "Submit"
    expect(page.find("#rw-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."
    expect(page.find("#btn-add-rw-user")).to be_disabled
    fill_in "rw-user-uid-to-add", with: ""
    click_on "Submit"
    expect(page.find("#rw-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."
    expect(page.find("#btn-add-rw-user")).to be_disabled
    fill_in "rw-user-uid-to-add", with: read_write.uid
    click_on "Submit"
    click_on "btn-add-rw-user"
    expect(page.find("#rw-user-uid-to-add").native.attribute("validationMessage")).to eq ""

    fill_in "directory", with: "test_project"
    fill_in "title", with: "My test project"
    expect(page).to have_content("Project Directory: /td-test-001/")
    expect do
      click_on "Submit"
    end.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1).times
    expect(page).to have_content "New Project Request Received"
    click_on "Return to Dashboard"
    click_on("My test project")
    expect(page).to have_content("This project has not been saved to Mediaflux"
    expect(page).to have_content("My test project (pending)")
    expect(page).to have_content("My test project (#{::Project::PENDING_STATUS})")
    expect(page).to have_content(read_only.display_name_safe + " (read only)")
    expect(page).to have_content(read_write.display_name_safe)
  end
end
