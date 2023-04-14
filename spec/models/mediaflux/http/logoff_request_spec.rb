# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::LogoutRequest, type: :model do
  subject(:request) { described_class.new(session_token: session_token) }

  let(:session_token) { "test-session-token" }
  let(:metdata_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "generic_response.xml")
    File.new(filename).read
  end

  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  before do
    stub_request(:post, mediflux_url)
      .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"server.logoff\" session=\"test-session-token\"/>\n</request>\n")
      .to_return(status: 200, body: metdata_response, headers: {})
  end

  describe "#resolve" do
    it "disconnects the session" do
      request.resolve
      expect(WebMock).to have_requested(:post, mediflux_url)
    end
  end
end
