# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectList do
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:project_list) { described_class.new(user, "namespace>='/princeton/tigerdataNS/RDSSNS' and xpath(tigerdata:project/ProjectID) has value") }

  describe "#all_projects" do
    it "returns the projects that the user has access to in Mediaflux" do
      projects = project_list.all_projects
      expect(projects.count).to eq(4)
      expect(projects.pluck(:title)).to eq(["Project A", "Project B", "Project C", "Test Project"])
    end
  end
end
