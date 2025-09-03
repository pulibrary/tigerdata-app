# frozen_string_literal: true

require "rails_helper"
require "open-uri"
# This is the automated test to the Skeletor epic https://github.com/pulibrary/tigerdata-app/issues/1478
RSpec.describe "The Skeletor Epic", connect_to_mediaflux: true, js: true, integration: true do
  context "unauthenticated user" do
    it "shows the 'Log In' button" do
      visit "/"
      expect(page).to have_content "TigerData Web Portal"
      expect(page).to have_content "Log in"
      expect(page).to have_link "Accessibility", href: "https://accessibility.princeton.edu/help"
    end
  end

  # Authenticated user logging in
  context "authenticated user" do
    let(:current_user) { FactoryBot.create(:user, uid: "pul123", mediaflux_session: SystemUser.mediaflux_session) }
    it "redirects to the user's dashboard and shows the logout button" do
      sign_in current_user
      visit "/"
      expect(page).to have_content("Welcome, #{current_user.given_name}!")
      click_link current_user.uid.to_s
      expect(page).to have_content "Log out"
    end
  end

  context "sysadmin" do
    let(:current_sysadmin) { FactoryBot.create(:sysadmin, uid: "sys123", mediaflux_session: SystemUser.mediaflux_session) }
    let(:datasponsor) { FactoryBot.create(:project_sponsor, uid: "kl37") } # must be a valid netid
    let(:datamanager) { FactoryBot.create(:data_manager, uid: "rl3667") } # must be a valid netid
    before do
      datasponsor
    end
    it "allows the sysadmin to fill out the project" do
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      expect(Project.count).to eq 0
      sign_in current_sysadmin
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Basic Details"
      fill_in :project_title, with: "She was a Fairy"
      expect(page).to have_content "15/200 characters"
      fill_in :parent_folder, with: "Fairy"
      fill_in :project_folder, with: "Pixie Dust #{random_project_directory}"
      fill_in :description, with: "An awesome project to show the wizard is magic"
      expect(page).to have_content "46/1000 characters"
      expect(page).not_to have_content("(77777) RDSS-Research Data and Scholarship Services")
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select "(77777) RDSS-Research Data and Scholarship Services\u00A0", from: "department_find"
      # This is triggering the html5 element like it would normally if the page has focus
      page.find(:datalist_input, "department_find").execute_script("document.getElementById('department_find').dispatchEvent(new Event('input'))")
      expect(page).to have_content("(77777) RDSS-Research Data and Scholarship Services")
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
      click_on "Roles and People"
      fill_in :request_data_sponsor, with: datasponsor.uid
      fill_in :request_data_manager, with: datamanager.uid
      click_on "Review and Submit"
      click_on "Next"
      click_on "Approve request"
      expect(Project.last.metadata_json["project_id"]).to eq "10.34770/tbd"
      visit "/projects/#{Project.last.id}.xml"
      expect(page.body).to include("<resource")
    end
  end

  context "developer" do
    let(:current_developer) { FactoryBot.create(:developer, uid: "developer1", mediaflux_session: SystemUser.mediaflux_session) }
    let(:datasponsor) { FactoryBot.create(:project_sponsor, uid: "kl37") } # must be a valid netid
    let(:datamanager) { FactoryBot.create(:data_manager, uid: "rl3667") } # must be a valid netid
    before do
      datasponsor
    end
    it "allows the developer to fill out the project" do
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      expect(Project.count).to eq 0
      sign_in current_developer
      visit "/"
      click_on "New Project Request"
      expect(page).to have_content "Basic Details"
      fill_in :project_title, with: "She was a Fairy"
      expect(page).to have_content "15/200 characters"
      fill_in :parent_folder, with: "Fairy"
      fill_in :project_folder, with: "Pixie Dust #{random_project_directory}"
      fill_in :description, with: "An awesome project to show the wizard is magic"
      expect(page).to have_content "46/1000 characters"
      expect(page).not_to have_content("(77777) RDSS-Research Data and Scholarship Services")
      # Non breaking space `u00A0` is at the end of every option to indicate an option was selected
      select "(77777) RDSS-Research Data and Scholarship Services\u00A0", from: "department_find"
      # This is triggering the html5 element like it would normally if the page has focus
      page.find(:datalist_input, "department_find").execute_script("document.getElementById('department_find').dispatchEvent(new Event('input'))")
      expect(page).to have_content("(77777) RDSS-Research Data and Scholarship Services")
      expect(page).to have_field("request[departments][]", type: :hidden, with: "{\"code\":\"77777\",\"name\":\"RDSS-Research Data and Scholarship Services\"}")
      click_on "Roles and People"
      fill_in :request_data_sponsor, with: datasponsor.uid
      fill_in :request_data_manager, with: datamanager.uid
      click_on "Review and Submit"
      click_on "Next"
      click_on "Approve request"
      expect(Project.last.metadata_json["project_id"]).to eq "10.34770/tbd"
      visit "/projects/#{Project.last.id}.xml"
      expect(page.body).to include("<resource")
    end
  end

  context "user" do
    let(:datasponsor) { FactoryBot.create(:project_sponsor) }
    let(:project) { FactoryBot.create(:project, data_sponsor: datasponsor.uid, data_manager: datamanager.uid) }
    let(:project_2) { FactoryBot.create(:project, data_sponsor: datasponsor.uid, data_manager: datamanager.uid, data_user_read_write: [user_b.uid]) }
    let(:datamanager) { FactoryBot.create(:data_manager) }
    let(:user_a) { FactoryBot.create(:user) }
    let(:user_b) { FactoryBot.create(:user) }
    it "does not allow a user to see someone elses project" do
      sign_in user_a
      visit "/projects/#{project.id}"
      expect(page).to have_content("Access Denied")
      visit "/projects/#{project.id}.xml"
      expect(page).to have_content("Access Denied")
    end
    it "allows a user to see a project they are affiliated with" do
      sign_in user_b
      visit "/projects/#{project_2.id}"
      expect(page).to have_content(project_2.title)
      visit "/projects/#{project_2.id}.xml"
      expect(page.body).to include(project_2.title)
    end
  end
end

# once a sysadmin or developer click on approve request then it should take us to the details page and display the project ID. This is the fake DOI (10.34770/tbd)

describe "#file_list", integration: true do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:manager) { sponsor_and_data_manager_user }
  let(:current_sysadmin) { FactoryBot.create(:sysadmin, uid: "sys123", mediaflux_session: SystemUser.mediaflux_session) }
  let(:user) { FactoryBot.create(:user) }
  let(:project) do
    project = FactoryBot.create(:approved_project, title: "project 111", data_manager: manager.uid)
    project.mediaflux_id = nil
    project
  end

  before do
    # Save the project in mediaflux
    project.approve!(current_user: manager)

    # create a collection so it can be filtered
    Mediaflux::AssetCreateRequest.new(session_token: manager.mediaflux_session, name: "sub-collectoion", pid: project.mediaflux_id).resolve

    # Create files for the project in mediaflux using test asset create request
    Mediaflux::TestAssetCreateRequest.new(session_token: manager.mediaflux_session, parent_id: project.mediaflux_id, pattern: "Real_Among_Random.txt").resolve
    Mediaflux::TestAssetCreateRequest.new(session_token: manager.mediaflux_session, parent_id: project.mediaflux_id, count: 7, pattern: "#{FFaker::Book.title}.txt").resolve
  end

  it "fetches the file list" do
    file_list = project.file_list(session_id: manager.mediaflux_session, size: 10)
    expect(file_list[:files].count).to eq 8
    expect(file_list[:files][0].name).to eq "Real_Among_Random.txt0"
    expect(file_list[:files][0].path).to eq "/princeton/#{project.project_directory}/Real_Among_Random.txt0"
    expect(file_list[:files][0].size).to be 100
    expect(file_list[:files][0].collection).to be false
    expect(file_list[:files][0].last_modified).to_not be nil
  end

  it "allows a user to see the file list" do
    sign_in manager
    visit "/projects/#{project.id}"
    click_on "Download Complete List"
    expect(page).to have_content "List Project Contents"
    execute_script('document.getElementById("request-list-contents").click();')
    expect(page).to have_content "A link to the downloadable file list"
  end
  it "does not allow an unaffiliated user to see the file list" do
    sign_in user
    visit "/projects/#{project.id}"
    expect(page).to have_content("Access Denied")
  end
  it "does not allow a user to approve a project" do
    sign_in user
    visit "/requests/#{project.id}" # this is the url a sysadmin can approve a project
    expect(page).to have_content("You do not have access to this page.")
  end
end
