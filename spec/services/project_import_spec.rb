# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectImport do
  let(:csv_data) { file_fixture("project_report.csv").read }
  let(:subject) { described_class.new(csv_data) }

  describe "#run" do
    it "flags the missing users" do
      expect {
        output = subject.run
        expect(output[0]).to include("Error creating project for 4894926: Invalid netid: uid2 for role Data Manager")
        expect(output[1]).to include("Error creating project for 4894935: Invalid netid: uid1 for role Data Manager")
        expect(output[2]).to include("Error creating project for 4897938: Invalid netid: uid4 for role Data Manager")
      }.to change { Project.count }.by(0)
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
        expect {
          output = subject.run
          expect(output[0]).to eq("Created project for 10.00000/1234-abcd")
          expect(output[1]).to eq("Created project for 10.00000/1234-efgh")

          # with liberal parsing we will try to create a record, but fail due to errors in the data
          expect(output[2]).to include("Error creating project for 4897938: Invalid netid: a dataset \\b\" for role Data Sponsor")

        }.to change { Project.count }.by(2)
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
          expect { subject.run }.to change { Project.count }.by(2)
        end
      end
    end
  end

  describe "##run_with_report" do
    let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
    let (:user) {FactoryBot.create :sysadmin, mediaflux_session: SystemUser.mediaflux_session}

    before do
      # Make sure we start with a clean slate
      namespace_to_clear = "princeton/tigerdataNS/rspec-importNS"
      Mediaflux::NamespaceDestroyRequest.new(session_token: SystemUser.mediaflux_session, namespace: namespace_to_clear, ignore_missing: true).destroy
    end

    it "creates projects for project in Mediaflux",
    :integration do
      # Create a project in Mediaflux...
      # (the rspec-import prefix is so that we don't ignore it just because it's a test project)
      new_project_id = random_project_id
      new_project_directory = "tigerdata/rspec-import/#{random_project_directory}"
      new_project = FactoryBot.create(:approved_project, project_id: new_project_id, project_directory: new_project_directory)
      new_project.approve!(current_user: user)

      # ...and delete it from the Rails database
      # (but it still exists in Mediaflux)
      new_project.destroy

      import_results = described_class.run_with_report(mediaflux_session: user.mediaflux_session)
      expect(import_results).to include("Created project for #{new_project_id}")
    end
  end
end
