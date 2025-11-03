# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectShowPresenter, type: :model, connect_to_mediaflux: false do
  let!(:current_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:request) { FactoryBot.create :request_project, data_manager: current_user.uid, data_sponsor: current_user.uid }
  let(:project) { request.approve(current_user) }
  subject(:presenter) { ProjectShowPresenter.new(project, current_user) }

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
      expect(presenter.project_directory).to eq("/" + project.metadata_model.project_directory)
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

  describe "#xml_document" do
    it "builds the XML document for the Project" do
      expect(presenter.xml_document).to be_a(Nokogiri::XML::Document)
    end
  end

  describe "#to_xml" do
    it "generates the string-serialized XML for the Project XML Document" do
      expect(presenter.to_xml).to be_a(String)
    end
  end
end
