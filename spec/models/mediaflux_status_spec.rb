# frozen_string_literal: true
require "rails_helper"

RSpec.describe MediafluxStatus, connect_to_mediaflux: true, type: :model do
  context "when Mediaflux is up and running" do
    it "reports status OK" do
      status = described_class.new
      expect { status.check! }.not_to raise_error
    end
  end

  context "when we cannot connecto Mediaflux" do
    let(:mediaflux_url) { Mediaflux::Request.uri.to_s }
    let(:error_node) { "<response><reply><error>something went wrong</error></reply></response>" }
    before do
      stub_request(:post, mediaflux_url)
        .to_return(status: 400, body: "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n#{error_node}")
    end

    it "reports that the status is not OK" do
      status = described_class.new
      expect { status.check! }.to raise_error(StandardError)
    end
  end
end
