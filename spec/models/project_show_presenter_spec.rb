# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectShowPresenter, type: :model, connect_to_mediaflux: false do
  let(:project) { FactoryBot.create :project }
  subject(:presenter) { ProjectShowPresenter.new(project) }

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

  describe "#pending?" do
    it "delegates to project" do
      expect(presenter.pending?).to eq(project.pending?)
    end
  end

  describe "#project_directory" do
    it "delegates to project" do
      expect(presenter.project_directory).to eq(project.project_directory)
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
