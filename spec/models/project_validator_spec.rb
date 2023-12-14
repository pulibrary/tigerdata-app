# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectValidator, type: :model do
  describe "#sponsored_projects" do
    context "with valid roles" do
      it "finds no errors" do
        sponsor = FactoryBot.create(:project_sponsor)
        project = FactoryBot.create(:project, data_sponsor: sponsor.uid, data_manager: sponsor.uid)
        expect(project).to be_valid
      end
    end

    context "with missing data sponsor" do
      it "finds the error" do
        sponsor = FactoryBot.create(:project_sponsor)
        project = FactoryBot.build(:project, data_sponsor: nil, data_manager: sponsor.uid)
        expect(project).not_to be_valid
        expect(project.errors.map(&:full_message)).to eq(["Mising netid for role Data Sponsor"])
      end
    end

    context "with missing project sponsor" do
      it "finds the error" do
        sponsor = FactoryBot.create(:project_sponsor)
        project = FactoryBot.build(:project, data_sponsor: sponsor.uid, data_manager: nil)
        expect(project).not_to be_valid
        expect(project.errors.map(&:full_message)).to eq(["Mising netid for role Data Manager"])
      end
    end

    context "with invalid ids" do
      it "finds the errors" do
        project = FactoryBot.build(:project, data_sponsor: "xx123", data_manager: "yy456")
        expect(project).not_to be_valid
        expect(project.errors.map(&:full_message)).to eq(["Invalid netid: yy456 for role Data Manager", "Invalid netid: xx123 for role Data Sponsor"])
      end
    end
  end
end
