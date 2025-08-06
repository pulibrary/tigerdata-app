# frozen_string_literal: true
require "rails_helper"

RSpec.describe TestProjectGenerator, connect_to_mediaflux: true do
  let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:subject) { described_class.new(user:, number: 1, project_prefix: "tigerdata/#{random_project_directory}" ) }

  before do
    Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
  end

  describe "#generate" do
    it "creates a project in mediaflux",
    :integration do
      subject.generate
      project = Project.last
      expect(project).to be_persisted
      metadata_query = Mediaflux::AssetMetadataRequest.new(
        session_token: user.mediaflux_session,
        id: project.mediaflux_id
      )
      metadata_query.resolve
      expect(metadata_query.metadata[:path]).to eq "/princeton/#{project.metadata_model.project_directory}"
      Mediaflux::AssetDestroyRequest.new(session_token: user.mediaflux_session, collection: project.mediaflux_id, members: true).resolve
    end
  end
end
