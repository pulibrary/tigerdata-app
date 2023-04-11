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
  let(:version_response_body) do
    filename = Rails.root.join("spec", "fixtures", "files", "version_response.xml")
    File.new(filename).read.gsub("sessiontoken", session_token)
  end
  let(:namespace_list_response_body) do
    filename = Rails.root.join("spec", "fixtures", "files", "namespace_list_response.xml")
    File.new(filename).read.gsub("sessiontoken", session_token)
  end
  let(:namespace_describe_response_body) do
    filename = Rails.root.join("spec", "fixtures", "files", "namespace_describe_response.xml")
    File.new(filename).read.gsub("sessiontoken", session_token)
  end
  let(:system_logoff_response_body) do
    filename = Rails.root.join("spec", "fixtures", "files", "system_logoff_response.xml")
    File.new(filename).read.gsub("sessiontoken", session_token)
  end
  let(:asset_store_list_response_body) do
    filename = Rails.root.join("spec", "fixtures", "files", "asset_store_list_response.xml")
    File.new(filename).read.gsub("sessiontoken", session_token)
  end
end

RSpec.configure do |config|
  config.include_context("Mediaflux server API")

  config.before(:each) do |ex|
    if ex.metadata[:stub_mediaflux]
      # Stubbing the asset.collection.list request
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
        body: /<service name=\"asset.collection.list\" session=\"test-session-token\">/
      ).to_return(status: 200, body: collection_list_response_body)

      # Stubbing the system.logon request
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with(
        body: /<service name="system.logon">/
      ).to_return(status: 200, body: logon_response_body)

      # Stubbing login when url has a slash at the end (I believe this is coming from the mediaflux_client direct connects)
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__/").with(
        body: /<service name="system.logon">/
      ).to_return(status: 200, body: logon_response_body)

      # Stubbing the system.version request
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__/")
        .with(
           body: /<service name=\"server.version\" session=\"test-session-token\"\/>/
         ).to_return(status: 200, body: version_response_body)

      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__/")
        .with(
          body: /<service name=\"asset.namespace.list\" session=\"test-session-token\" data-out-min=\"0\" data-out-max=\"0\">/
        ).to_return(status: 200, body: namespace_list_response_body)
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__/")
        .with(
          body: /<service name=\"asset.namespace.describe\" session=\"test-session-token\" data-out-min=\"0\" data-out-max=\"0\">/
        ).to_return(status: 200, body: namespace_describe_response_body)
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__/")
        .with(
          body: /<service name="system.logoff" session="test-session-token"\/>/
        ).to_return(status: 200, body: system_logoff_response_body)
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__/")
        .with(
          body: /<service name="asset.store.list" session="test-session-token" data-out-min="0" data-out-max="0">/
        ).to_return(status: 200, body: asset_store_list_response_body)
    end
  end
end
