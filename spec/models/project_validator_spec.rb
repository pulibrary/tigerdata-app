# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectValidator, type: :model do
  describe "#sponsored_projects" do
    context "with valid roles" do
      it "finds no errors" do
        sponsor = FactoryBot.create(:project_sponsor)
        project = FactoryBot.create(:project, data_sponsor: sponsor.uid, data_manager: sponsor.uid, project_id: "abc123")
        expect(project).to be_valid
      end
    end

    context "with missing schema version" do
      it "finds the error" do
        sponsor = FactoryBot.create(:project_sponsor)
        project = FactoryBot.build(:project, data_sponsor: nil, data_manager: sponsor.uid, project_id: "abc123", schema_version: nil)
        expect(project).not_to be_valid
        expect(project.errors.map(&:full_message)).to eq(["Missing netid for role Data Sponsor",
                                                          "Invalid Project Metadata it does not match the schema 0.6.1\n Missing metadata value for data_sponsor"])
      end
    end

    context "with missing data sponsor" do
      it "finds the error" do
        sponsor = FactoryBot.create(:project_sponsor)
        project = FactoryBot.build(:project, data_sponsor: nil, data_manager: sponsor.uid, project_id: "abc123")
        expect(project).not_to be_valid
        expect(project.errors.map(&:full_message)).to eq(["Missing netid for role Data Sponsor",
                                                          "Invalid Project Metadata it does not match the schema 0.6.1\n Missing metadata value for data_sponsor"])
      end
    end

    context "with missing project sponsor" do
      it "finds the error" do
        sponsor = FactoryBot.create(:project_sponsor)
        project = FactoryBot.build(:project, data_sponsor: sponsor.uid, data_manager: nil)
        expect(project).not_to be_valid
        expect(project.errors.map(&:full_message)).to eq(["Missing netid for role Data Manager",
                                                          "Invalid Project Metadata it does not match the schema 0.6.1\n Missing metadata value for data_manager"])
      end
    end

    context "with invalid ids" do
      it "finds the errors" do
        project = FactoryBot.build(:project, data_sponsor: "xx123", data_manager: "yy456")
        expect(project).not_to be_valid
        expect(project.errors.map(&:full_message)).to eq(["Invalid netid: yy456 for role Data Manager", "Invalid netid: xx123 for role Data Sponsor"])
      end
    end

    context "with invalid data readers" do
      it "finds the errors" do
        project = FactoryBot.build(:project, data_user_read_only: ["xxx"])
        expect(project).not_to be_valid
        expect(project.errors.map(&:full_message)).to eq(["Invalid netid: xxx for role Data User Read Only"])
      end
    end

    context "with invalid data writers" do
      it "finds the errors" do
        project = FactoryBot.build(:project, data_user_read_write: ["xxx"])
        expect(project).not_to be_valid
        expect(project.errors.map(&:full_message)).to eq(["Invalid netid: xxx for role Data User Read Write"])
      end
    end
  end
end
