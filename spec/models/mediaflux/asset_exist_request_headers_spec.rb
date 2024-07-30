# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::AssetExistRequest, type: :model, connect_to_mediaflux: false do
  let(:user) { FactoryBot.create(:user) }
  let(:session_token) { user.mediaflux_session }
  let(:namespace_root) { Rails.configuration.mediaflux["api_root_collection_namespace"] }
  let(:name) { FFaker::InternetSE.company_name_single_word }
  let(:login_response) do
    <<-XML_BODY
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
          <reply type="result">
              <result>
                  <session id="54" timeout="1800" wallet="true">test-session-token</session>
                  <locale>en-US</locale>
                  <user username="manager">
                      <name />
                  </user>
              </result>
          </reply>
      </response>
    XML_BODY
  end

  let(:asset_exists_response) do
    <<-XML_BODY
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
          <reply type="result">
              <result>
                  <exists>true</exists>
              </result>
          </reply>
      </response>
    XML_BODY
  end

  before do
    WebMock.enable!
    WebMock.disable_net_connect!

    stub_request(:post, "http://0.0.0.0:8888/__mflux_svc__").with(
      body: /<service name="system.logon">/
    ).to_return(status: 200, body: login_response)

    stub_request(:post, "http://0.0.0.0:8888/__mflux_svc__").with(
      body: /<service name="asset.exists"/,
      headers: { 'mediaflux.sso.user' => user.uid },  # Our custom HTTP header
    ).to_return(status: 200, body: asset_exists_response)
  end

  context "when we pass a user to the class" do
    it "passes the custom HTTP headers to Mediaflux" do
      subject = described_class.new(session_token: nil, session_user: user, path: namespace_root)
      expect(subject.exist?).to be true
    end
  end

end
