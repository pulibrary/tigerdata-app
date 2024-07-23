# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::StoreListRequest, connect_to_mediaflux: true, type: :model do
  let(:mediflux_url) { "http://0.0.0.0:8888/__mflux_svc__" }
  let(:user) { FactoryBot.create(:user) }
  let(:approved_project) { FactoryBot.create(:approved_project) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<response><reply type=\"result\"><result></result></reply></response>" }

  describe "#metadata" do
    before do
      # create a real collection for the test to make a request to
      approved_project.mediaflux_id = nil
      @mediaflux_id = ProjectMediaflux.create!(project: approved_project, session_id: user.mediaflux_session)
    end
    it "parses a metadata response" do
      stores_request = described_class.new(session_token: user.mediaflux_session)
      stores = stores_request.stores
      expect(stores.count).to eq(5)
      expect(stores.first).to eq({ id: "1", name: "db", tag: "", type: "database" })
    end
  end
end
