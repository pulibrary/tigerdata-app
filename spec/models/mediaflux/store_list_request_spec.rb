# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::StoreListRequest, connect_to_mediaflux: true, type: :model do
  let(:mediaflux_url) { Mediaflux::Request.uri.to_s }
  let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "hc8719", mediaflux_session: SystemUser.mediaflux_session) }
  let(:approved_project) { FactoryBot.create(:approved_project) }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<response><reply type=\"result\"><result></result></reply></response>" }
  # Docker and Ansible responses are the same, but may be different in the future
  let(:docker_response_store) { { id: "1", name: "db", tag: "", type: "database" } }
  let(:ansible_response_store) { { id: "1", name: "db", tag: "", type: "database" } }

  describe "#metadata" do
    before do
      # create a real collection for the test to make a request to
      approved_project.mediaflux_id = nil
      @mediaflux_id = ProjectMediaflux.create!(project: approved_project, user:)
    end
    it "parses a metadata response" do
      stores_request = described_class.new(session_token: user.mediaflux_session)
      stores = stores_request.stores
      expect(stores.count).to eq(2).or eq(5)
      expect(stores.first).to eq(docker_response_store).or eq(ansible_response_store)
    end
  end
end
