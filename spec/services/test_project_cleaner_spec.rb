# frozen_string_literal: true
require "rails_helper"

RSpec.describe TestProjectCleaner, type: :service do
  let!(:project_a) { test_project_from_path("/princeton/tigerdata/RDSS/Query/AProject") }
  let!(:project_b) { test_project_from_path("/princeton/tigerdata/RDSS/Query/BProject") }
  let!(:other_project) { create_project_in_mediaflux }
  let(:cleaner) { TestProjectCleaner.new }

  describe "#clean" do
    it "removes test projects, but leaves other projects" do
      expect(Project.count).to eq(3)
      expect do
        cleaner.clean
      end.to change { Project.count }.from(3).to(1)
    end
  end

  describe "#reload" do
    it "creates a new project with the attributes from mediaflux" do
      cleaner.reload
      new_project_a = Project.find_by(mediaflux_id: project_a.mediaflux_id)
      expect(new_project_a).not_to be_nil
      expect(new_project_a.id).not_to eq(project_a.id)
      expect(new_project_a.title).to eq(project_a.title)
      new_project_b = Project.find_by(mediaflux_id: project_b.mediaflux_id)
      expect(new_project_b).not_to be_nil
      expect(new_project_b.id).not_to eq(project_b.id)
      expect(new_project_b.title).to eq(project_b.title)
    end
  end
end
