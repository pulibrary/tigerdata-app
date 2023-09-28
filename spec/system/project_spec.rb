# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project Page", type: :system, stub_mediaflux: true do
  let(:sponsor_user) { FactoryBot.create(:user, uid: "pul123") }
  let(:metadata) do
    {
      data_sponsor: "pul123",
      data_manager: "pul987",
      directory: "project-123",
      title: "project 123",
      departments: ["RDSS"],
      description: "hello world"
    }
  end

  let(:project_not_in_mediaflux) do
    Project.create(metadata: metadata)
  end

  let(:project_in_mediaflux) do
    project = Project.create(metadata: metadata)
    project.approve!(session_id: sponsor_user.mediaflux_session, created_by: sponsor_user.uid)
    project
  end

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
    it "shows the project data" do
      sign_in sponsor_user
      visit "/projects/#{project_not_in_mediaflux.id}"
      expect(page).to have_content "project 123"
      expect(page).to have_content "This project has not been saved to Mediaflux"
    end

    it "shows the Mediaflux id for a project saved in Mediaflux" do
      sign_in sponsor_user
      visit "/projects/#{project_in_mediaflux.id}"
      expect(page).to have_content "project 123"
      expect(page).to have_content "Mediaflux id: 999"
    end
  end

  context "Edit page" do
    it "preserves the readonly directory field" do
      sign_in sponsor_user
      visit "/projects/#{project_in_mediaflux.id}/edit"
      click_on "Save"
      project_in_mediaflux.reload
      expect(project_in_mediaflux.metadata[:directory]).to eq "project-123"
    end
  end
end
