# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizations", stub_mediaflux: true do
  let(:user) { FactoryBot.create(:user, uid: "pul123") }
  before do
    sign_in user

    # Stubbing data here to force the code to go through create_defaults, so it is tested
    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
      .with(
      body: /<service name="asset.namespace.list" session="test-session-token">/
    ).to_return({ status: 200, body: namespace_list_root_error_response_body }, # first time in list nothing exists
                { status: 200, body: namespace_list_response_body }) # after that the root namespace exists

    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
      .with(
      body: /<service name="asset.namespace.describe" session="test-session-token">/
    ).to_return({ status: 200, body: namespace_desrcibe_root_error_response_body }, # first time in describe the root namespace does not exists
                { status: 200, body: namespace_describe_response_body }) # after that the root namespace exists

    stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").with do |request|
      request.body.include?("asset.namespace.create") && request.body.include?("td-test-001")
    end.to_return(status: 200, body: namespace_create_root_response_body)
  end
  # Commented while we shuffle around the MediaFlux code.
  # It is very likely we are not going to manage organizations in MF per-se.
  #
  # it "shows the organizations" do
  #   visit "/"
  #   click_on "Organizations"
  #   expect(page).to have_content("Princeton Physics Plasma Lab")
  #   # Only login once when loading multiple pages
  #   assert_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
  #                    body: /<service name="system.logon">/)
  # end
end
