# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Connection, type: :model do

  let(:login_response) do
    filename = Rails.root.join("spec", "fixtures", "login_response.xml")
    File.new(filename).read
  end

  describe "#initialize" do
    before do
      stub_request(:post, "http://test.mediaflux.com:8888/__mflux_svc__").
         with(
           body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"system.logon\">\n    <args>\n      <domain>system</domain>\n      <user>manager</user>\n      <password>change_me</password>\n    </args>\n  </service>\n</request>\n",
           headers: {
       	  'Accept'=>'*/*',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'Content-Type'=>'text/xml; charset=utf-8',
       	  'User-Agent'=>'Ruby'
           }).
         to_return(status: 200, body: login_response, headers: {})
    end
    it "logs the user in" do
      connection = described_class.new()
      expect(connection.session).to eq("secretsecret/2/31")
      assert_requested :post, "http://test.mediaflux.com:8888/__mflux_svc__" 
    end
  end
end
