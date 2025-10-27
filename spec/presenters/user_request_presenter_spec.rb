# frozen_string_literal: true
require "rails_helper"

describe UserRequestPresenter, type: :model, connect_to_mediaflux: false do
  subject(:presenter) { described_class.new(user_request) }

  let(:user_request) do
    FileInventoryRequest.create(
      user_id: current_user.id,
      project_id: project.id,
      job_id: "ccbb63c0-a8cd-47b7-8445-5d85e9c80977",
      state: UserRequest::COMPLETED,
      request_details: {
        project_title: project.title,
        file_size: 1_000_000
      },
      completion_time: Time.current.in_time_zone("America/New_York")
    )
  end

  let(:current_user) { FactoryBot.create :user, uid: "tigerdatatester" }
  let(:project) do
    FactoryBot.create :project_with_apostrophe_in_title,
    data_manager: current_user.uid,
    data_sponsor: current_user.uid
  end

  describe "#title" do
    it "returns the project title" do
      expect(presenter.title).to eq(project.title)
    end
  end

  describe "#list_contents_url" do
    it "returns the project list_contents_url" do
      expect(presenter.list_contents_url).to eq("/projects/#{project.id}/list-contents")
    end
  end

  describe "#download_link" do
    it "returns the project download_link" do
      # Note that we have to html escape the title, because that's what rails will do, and when
      # we get sample data with special characters in the title, we want to make sure the test still passes.
      html_escaped_title = CGI.escapeHTML(project.title)
      expect(presenter.download_link).to eq("<a href=\"/projects/file_list_download/ccbb63c0-a8cd-47b7-8445-5d85e9c80977\">#{html_escaped_title}</a>")
    end
  end

  describe "#expiration" do
    it "returns the project expiration" do
      expect(presenter.expiration).to eq("Expires in 7 days")
    end
  end

  describe "#size" do
    it "returns the project size" do
      expect(presenter.size).to eq("977 KB")
    end
  end

  describe "#partial_name" do
    it "returns 'download_item'" do
      expect(presenter.partial_name).to eq("download_item")
    end

    context "a failed user request" do
      let(:user_request) do
        FileInventoryRequest.create(user_id: current_user.id, project_id: project.id, job_id: "ccbb63c0-a8cd-47b7-8445-5d85e9c80977", state: UserRequest::FAILED,
                                    request_details: { project_title: project.title }, completion_time: Time.current.in_time_zone("America/New_York"))
      end
      it "returns 'failed_item'" do
        expect(presenter.partial_name).to eq("failed_item")
      end
    end
  end
end
