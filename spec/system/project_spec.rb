# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Page", type: :system, stub_mediaflux: true do
  let(:sponsor_user) { FactoryBot.create(:user, uid: "pul123") }
  let(:data_manager) { FactoryBot.create(:user, uid: "pul987") }
  let(:read_only) { FactoryBot.create :user }
  let(:read_write) { FactoryBot.create :user }
  let(:pending_text) do
    "Your new project request is in the queue. Please allow 5 business days for our team to review your needs and set everything up. For assistance, please contact tigerdata@princeton.edu."
  end
  let(:metadata) do
    {
      data_sponsor: sponsor_user.uid,
      data_manager: data_manager.uid,
      directory: "project-123",
      title: "project 123",
      departments: ["RDSS"],
      description: "hello world",
      data_user_read_only: [read_only.uid],
      data_user_read_write: [read_write.uid]
    }
  end

  let(:project_not_in_mediaflux) { FactoryBot.create(:project, metadata: metadata) }

  before do
    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
      .with(
        body: /<service name="asset.namespace.create" session="test-session-token">/
      ).to_return(status: 200, body: "<xml>something</xml>")

    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
      .with(
        body: /<service name="asset.create" session="test-session-token">/
      ).to_return(status: 200, body: "<?xml version=\"1.0\" ?> <response> <reply type=\"result\"> <result> <id>999</id> </result> </reply> </response>")

    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
      .with(
        body: /<service name="asset.set" session="test-session-token">/
      ).to_return(status: 200, body: "<?xml version=\"1.0\" ?> <response> <reply type=\"result\"> <result> <id>999</id> </result> </reply> </response>")

    sign_in sponsor_user
  end

  context "Show page" do
    context "Before it is in MediaFlux" do
      it "Shows the not yet approved project" do
        sign_in sponsor_user
        visit "/projects/#{project_not_in_mediaflux.id}"
        expect(page).to have_content "(pending)"
        expect(page).to have_content pending_text
      end
    end

    context "when the data user is empty" do
      let(:metadata) do
        {
          data_sponsor: sponsor_user.uid,
          data_manager: data_manager.uid,
          directory: "project-123",
          title: "project 123",
          departments: ["RDSS"],
          description: "hello world",
          data_user_read_only: [],
          data_user_read_write: []
        }
      end

      it "shows none when the data user is empty" do
        sign_in sponsor_user
        visit "/projects/#{project_not_in_mediaflux.id}"
        expect(page).to have_content "project 123 (pending)"
        expect(page).to have_content "This project has not been saved to Mediaflux"
        expect(page).to have_content pending_text
        expect(page).not_to have_button "Approve Project"
        expect(page).to have_content "Read Only\nNone"
        expect(page).to have_content "Read/write\nNone"
        expect(page).to be_axe_clean
          .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
          .skipping(:'color-contrast')
      end
    end
    context "An Mediaflux Administrator" do
      let(:mediaflux_admin_user) { FactoryBot.create(:mediaflux_admin) }

      it "shows the project data and the Approve Project button" do
        sign_in mediaflux_admin_user
        visit "/projects/#{project_not_in_mediaflux.id}"
        expect(page).to have_content "project 123 (pending)"
        expect(page).to have_content "This project has not been saved to Mediaflux"
        expect(page).to have_content pending_text
        expect(page).to have_button "Approve Project"
      end
    end
  end

  context "Edit page" do
    before do
      sign_in sponsor_user
      visit "/projects/#{project_not_in_mediaflux.id}/edit"
    end
    it "preserves the readonly directory field" do
      click_on "Submit"
      project_not_in_mediaflux.reload
      expect(project_not_in_mediaflux.metadata[:directory]).to eq "project-123"
    end
    it "loads existing content into the form" do
      expect(page.find("#data_sponsor").value).to eq sponsor_user.uid
    end
  end

  context "Create page" do
    before do
      # make sure the users exist before the page loads
      data_manager
      read_only
      read_write
    end

    it "allows the user to create a project" do
      sign_in sponsor_user
      visit "/"
      click_on "New Project"
      expect(page.find("#data_sponsor").value).to eq sponsor_user.uid
      fill_in "data_manager", with: data_manager.uid
      fill_in "ro-user-uid-to-add", with: read_only.uid
      click_on "btn-add-ro-user"
      fill_in "rw-user-uid-to-add", with: read_write.uid
      click_on "btn-add-rw-user"
      fill_in "directory", with: "test_project"
      fill_in "title", with: "My test project"
      expect(page).to have_content("Project Directory: /td-test-001/")
      expect do
        click_on "Submit"
      end.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1).times
      # This is the confirmation page. It needs a button to return to the dashboard
      # and it needs to be_axe_clean.
      expect(page).to have_content "New Project Request Received"
      expect(page).to have_button "Return to Dashboard"
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :section508)
        .skipping(:'color-contrast')
      click_on "Return to Dashboard"
      expect(page).to have_content "Sponsored by Me"
    end

    it "does not allow the user to create a project without a data sponsor" do
      sign_in sponsor_user
      visit "/"
      click_on "New Project"
      expect(page.find("#data_sponsor").value).to eq sponsor_user.uid
      fill_in "data_sponsor", with: ""
      click_on "Submit"
      expect(page.find("#data_sponsor").native.attribute("validationMessage")).to eq "Please select a valid value."
    end
    context "with an invalid data manager" do
      it "does not allow the user to create a project" do
        sign_in sponsor_user
        visit "/"
        click_on "New Project"
        expect(page.find("#data_sponsor").value).to eq sponsor_user.uid
        # fill_in "data_sponsor", with: sponsor_user.uid
        fill_in "data_manager", with: "xxx"
        fill_in "ro-user-uid-to-add", with: read_only.uid
        expect(page.find("#data_manager").native.attribute("validationMessage")).to eq "Please select a valid value."
        click_on "btn-add-ro-user"
        fill_in "rw-user-uid-to-add", with: read_write.uid
        click_on "btn-add-rw-user"
        fill_in "directory", with: "test_project"
        fill_in "title", with: "My test project"
        expect(page).to have_content("Project Directory: /td-test-001/")
        expect do
          click_on "Submit"
        end.not_to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1).times
      end
    end

    context "with an invalid data users" do
      it "does not allow the user to create a project" do
        sign_in sponsor_user
        visit "/"
        click_on "New Project"
        expect(page.find("#data_sponsor").value).to eq sponsor_user.uid
        fill_in "data_manager", with: data_manager.uid
        fill_in "ro-user-uid-to-add", with: "xxx"
        click_on "btn-add-ro-user"
        expect(page.find("#ro-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."

        fill_in "rw-user-uid-to-add", with: "zzz"
        click_on "btn-add-rw-user"
        expect(page.find("#ro-user-uid-to-add").native.attribute("validationMessage")).to eq "Please select a valid value."
        fill_in "directory", with: "test_project"
        fill_in "title", with: "My test project"
        expect(page).to have_content("Project Directory: /td-test-001/")
        expect do
          click_on "Submit"
        end.not_to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(1).times
      end
    end
    context "upon cancelation" do
      it "redirects the user back to the dashboard" do
        sign_in sponsor_user
        visit "/"
        click_on "New Project"
        click_on "Cancel"
        expect(page).to have_content("Welcome, #{sponsor_user.given_name}!")
      end
    end
    context "when the directory name has invalid characters" do
      it "allows the user to create a project" do
        sign_in sponsor_user
        visit "/"
        click_on "New Project"
        fill_in "data_sponsor", with: sponsor_user.uid
        fill_in "data_manager", with: data_manager.uid
        fill_in "ro-user-uid-to-add", with: read_only.uid
        click_on "btn-add-ro-user"
        fill_in "rw-user-uid-to-add", with: read_write.uid
        click_on "btn-add-rw-user"
        fill_in "directory", with: "test?project"
        valid = page.find("input#directory:invalid")
        expect(valid).to be_truthy
        fill_in "title", with: "My test project"
        expect(page).to have_content("Project Directory: /td-test-001/")
        expect(page).to have_content("New Project")
      end
    end
  end

  context "Index page" do
    before do
      project_not_in_mediaflux
    end

    it "shows the existing projects" do
      sign_in sponsor_user
      visit "/projects"
      expect(page).to have_content(project_not_in_mediaflux.title)
      expect(page).to have_content("(pending)")
    end
  end
end
