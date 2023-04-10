# frozen_string_literal: true

RSpec.shared_context "Mediaflux server API" do
  let(:session_token) { "test-session-token" }
  let(:logon_response_body) do
    filename = Rails.root.join("spec", "fixtures", "files", "login_response.xml")
    File.new(filename).read.gsub("sessiontoken", session_token)
  end
  let(:collection_list_response_body) do
    filename = Rails.root.join("spec", "fixtures", "files", "collection_list_response.xml")
    File.new(filename).read.gsub("sessiontoken", session_token)
  end
end

RSpec.configure do |config|
  config.include_context("Mediaflux server API")

  config.before(:each) do |ex|
    if ex.metadata[:stub_mediaflux]
      WebMock.enable!

      # Stubbing the asset.collection.list request
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
        body: /<service name=\"asset.collection.list\" session=\"test-session-token\">/
      ).to_return(status: 200, body: collection_list_response_body)

      # Stubbing the system.logon request
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
        body: /<service name="system.logon">/
      ).to_return(status: 200, body: logon_response_body)
    end
  end
end
