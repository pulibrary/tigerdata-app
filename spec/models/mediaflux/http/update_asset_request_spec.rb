# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::UpdateAssetRequest, type: :model do
  let(:mediaflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }
  let(:metadata) do
    {
      code: "code",
      title: "title",
      description: "description",
      data_sponsor: "data_sponsor",
      data_manager: "data_manager",
      departments: ["RDSS", "HPC"]
    }
  end

  let(:update_request) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_update_request.xml")
    File.new(filename).read
  end

  let(:update_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_update_response.xml")
    File.new(filename).read
  end

  describe "metadata values" do
    before do
      stub_request(:post, mediaflux_url)
        .with(body: update_request)
        .to_return(status: 200, body: update_response, headers: {})
    end

    it "passes the metadata values in the request" do
      update_request = described_class.new(session_token: "secretsecret/2/31", id: "1234", tigerdata_values: metadata)
      update_request.resolve
      expect(WebMock).to have_requested(:post, mediaflux_url)
    end
  end
end
