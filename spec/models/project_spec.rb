# frozen_string_literal: true
require "rails_helper"

RSpec.describe Project, type: :model do
  describe "#sponsored_projects" do
    before do
      FactoryBot.create(:project, metadata: { data_sponsor: "hc1234", title: "project 111" })
      FactoryBot.create(:project, metadata: { data_sponsor: "hc1234", title: "project 222" })
      FactoryBot.create(:project, metadata: { data_sponsor: "zz8888", title: "project 333" })
    end

    it "returns projects for the sponsor" do
      sponsored_projects = described_class.sponsored_projects("hc1234")
      expect(sponsored_projects.find { |project| project.title == "project 111" }).not_to be nil
      expect(sponsored_projects.find { |project| project.title == "project 222" }).not_to be nil
      expect(sponsored_projects.find { |project| project.title == "project 444" }).to be nil
    end
  end
end
