# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectImport do
  let(:csv_data) { file_fixture("project_report.csv").read }
  let(:subject) { described_class.new(csv_data) }

  describe "#run" do
    it "flags the missing users" do
      expect { subject.run }.to raise_error(ActiveRecord::RecordInvalid)
    end

    context "when all users exist" do
      before do
        FactoryBot.create :user, uid: "uid1"
        FactoryBot.create :user, uid: "uid2"
        FactoryBot.create :user, uid: "uid3"
        FactoryBot.create :user, uid: "uid4"
        FactoryBot.create :user, uid: "uid5"
      end
      it "creates test data" do
        expect { subject.run }.to change { Project.count }.by(3)
        project_metadata = Project.first.metadata_model
        expect(project_metadata.project_id).to eq("10.00000/1234-abcd")
        expect(project_metadata.data_sponsor).to eq("uid1")
        expect(project_metadata.data_manager).to eq("uid2")
        expect(project_metadata.data_user_read_only).to eq(["uid3", "uid4"])
      end

      it "only imports the projects once" do
        subject.run # import projects to test that a second run does nothing
        expect { subject.run }.to change { Project.count }.by(0)
      end

      context "input is a file" do
        let(:csv_data) { File.new(file_fixture("project_report.csv")) }
        it "can also read a file IO" do
          expect { subject.run }.to change { Project.count }.by(3)
        end
      end
    end
  end
end
