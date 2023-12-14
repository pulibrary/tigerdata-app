# frozen_string_literal: true
require "rails_helper"

RSpec.describe Project, type: :model do
  describe "#sponsored_projects" do
    let(:sponsor) { FactoryBot.create(:user, uid: "hc1234") }
    before do
      FactoryBot.create(:project, title: "project 111", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 222", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 333", data_sponsor: sponsor.uid)
    end

    it "returns projects for the sponsor" do
      sponsored_projects = described_class.sponsored_projects("hc1234")
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 111" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 222" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 444" }).to be nil
    end
  end
end
