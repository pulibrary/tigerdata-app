# frozen_string_literal: true
require "rails_helper"

RSpec.describe TestProjectGenerator, connect_to_mediaflux: true do
  let(:subject) { described_class.new(user:, number: 1, project_prefix: 'test-project') }
  let(:user) { FactoryBot.create :user }

  describe "#generate" do
    it "creates a project in mediaflux" do
      subject.generate
      project = Project.last
      expect(project).to be_persisted
      metadata_query = Mediaflux::AssetMetadataRequest.new(
        session_token: user.mediaflux_session, 
        id: project.mediaflux_id
      )      
      metadata_query.resolve
      expect(metadata_query.metadata[:path]).to eq "/td-test-001/test/tigerdata/test-project-00001"
      Mediaflux::AssetDestroyRequest.new(session_token: user.mediaflux_session, collection: project.mediaflux_id, members: true).resolve
    end
  end
end
