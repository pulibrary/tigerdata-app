# frozen_string_literal: true
require "rails_helper"

describe "#file_list", integration: true do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:manager) { sponsor_and_data_manager_user }
  let(:current_sysadmin) { FactoryBot.create(:sysadmin, uid: "sys123", mediaflux_session: SystemUser.mediaflux_session) }
  let(:user) { FactoryBot.create(:user) }
  let(:request) { FactoryBot.create(:request_project) }
  let(:project) { request.approve(manager) }

  before do
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
  it "does not allow any user to visit the request" do
    sign_in user
    visit "/requests/#{request.id}"
    expect(page).to have_content("You do not have access to this page.")
  end
  it "does not allow the requestor to approve the request" do
    request.requested_by = user.uid
    request.save
    sign_in user
    visit "/requests/#{request.id}"
    expect(page).to have_content(request.project_title)
    expect(page).not_to have_content("Approve")
  end
end
