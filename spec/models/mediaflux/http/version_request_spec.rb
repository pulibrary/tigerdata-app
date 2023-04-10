# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::VersionRequest, type: :model do
  subject(:request) { described_class.new(session_token: session_token) }

  let(:session_token) { "test-session-token" }
  let(:response_body) do
    filename = Rails.root.join("spec", "fixtures", "files", "version_response.xml")
    File.new(filename).read
  end

  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  before do
    stub_request(:post, mediflux_url).to_return(status: 200, body: response_body)
  end

  describe "#resolve" do
    it "authenticates and stores the session token" do
      request.resolve

      expect(request.version[:vendor]).to eq("Arcitecta Pty. Ltd.")
      expect(request.version[:version]).to eq("4.14.014")
    end
  end
end
