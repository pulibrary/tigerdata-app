# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectDashboardPresenter, type: :model, connect_to_mediaflux: false do
  let!(:sponsor_and_data_manager) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:project) { FactoryBot.create :project }
  subject(:presenter) { ProjectDashboardPresenter.new(project) }

  describe "#type" do
    it "returns the requested type" do
      project.metadata_model.storage_performance_expectations["approved"] = nil
      presenter = ProjectDashboardPresenter.new(project)
      expect(presenter.type).to include("Requested")
    end

    context "an approved project" do
      let(:project) { FactoryBot.create :approved_project }

      it "returns the approved type" do
        expect(presenter.type).not_to include("Requested")
      end
    end
  end

  describe "#latest_file_list_time" do
    it "returns no downloads" do
      expect(presenter.latest_file_list_time).to eq("No Downloads")
    end

    context "when downloads exist" do
      before do
        FileInventoryRequest.create!(user_id: FactoryBot.create(:user).id, project_id: project.id, job_id: 123, state: UserRequest::PENDING,
                                     request_details: { project_title: project.title }, completion_time: 1.day.ago)
      end

      it "returns the time ago" do
        expect(presenter.latest_file_list_time).to eq("Prepared 1 day ago")
      end
    end

    context "when download in progress exist" do
      before do
        FileInventoryRequest.create!(user_id: FactoryBot.create(:user).id, project_id: project.id, job_id: 123, state: UserRequest::PENDING,
                                     request_details: { project_title: project.title }, completion_time: nil)
      end

      it "returns the time ago" do
        expect(presenter.latest_file_list_time).to eq("Preparing now")
      end
    end
  end

  describe "#last_activity" do
    it "last activity" do
      expect(presenter.last_activity).to eq("less than a minute ago")
    end

    # TODO: When can last activity actually be blank?
  end

  describe "#description" do
    it "delegates to project metdata_model" do
      expect(presenter.description).to eq(project.metadata_model.description)
    end
  end

  describe "#id" do
    it "delegates to project" do
      expect(presenter.id).to eq(project.id)
    end
  end

  describe "#in_mediaflux?" do
    it "delegates to project" do
      expect(presenter.in_mediaflux?).to eq(project.in_mediaflux?)
    end
  end

  describe "#mediaflux_id" do
    it "delegates to project" do
      expect(presenter.mediaflux_id).to eq(project.mediaflux_id)
    end
  end

  describe "#project_directory" do
    it "hides the root project" do
      expect(presenter.project_directory).to eq(project.metadata_model.project_directory)
    end
  end

  describe "#project_id" do
    it "delegates to project metdata_model" do
      expect(presenter.project_id).to eq(project.metadata_model.project_id)
    end
  end

  describe "#project_purpose" do
    it "delegates to project metdata_model" do
      expect(presenter.project_purpose).to eq(project.metadata_model.project_purpose)
    end
  end

  describe "#status" do
    it "delegates to project" do
      expect(presenter.status).to eq(project.status)
    end
  end

  describe "#storage_capacity" do
    it "delegates to project metadata_model" do
      expect(presenter.storage_capacity).to eq(project.metadata_model.storage_capacity)
    end
  end

  describe "#storage_performance_expectations" do
    it "delegates to project metadata_model" do
      expect(presenter.storage_performance_expectations).to eq(project.metadata_model.storage_performance_expectations)
    end
  end

  describe "#title" do
    it "delegates to project" do
      expect(presenter.title).to eq(project.title)
    end
  end
end
