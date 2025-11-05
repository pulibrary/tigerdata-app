# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::ProjectListRequest, connect_to_mediaflux: true, type: :model do
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }

  describe "#results" do
    it "query for a known project in Mediaflux" do
      request = described_class.new(session_token: user.mediaflux_session, aql_query: "xpath(tigerdata:project/ProjectDirectory) = 'tigerdata/RDSS/testing-project'")
      results = request.results
      expect(results.count).to be 1
      expect(results[0][:project_directory]).to eq "tigerdata/RDSS/testing-project"
    end
  end
end
