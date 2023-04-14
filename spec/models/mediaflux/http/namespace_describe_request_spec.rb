# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::NamespaceDescribeRequest, type: :model do
  let(:mediflux_url) { "http://mediaflux.example.com:8888/__mflux_svc__" }

  let(:namespace_response) do
    filename = Rails.root.join("spec", "fixtures", "files", "namespace_describe_response.xml")
    File.new(filename).read
  end

  describe "#metadata" do
    before do
      stub_request(:post, mediflux_url)
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.namespace.describe\" session=\"secretsecret/2/31\">\n    "\
                    "<args>\n      <id>1116</id>\n    </args>\n  </service>\n</request>\n")
        .to_return(status: 200, body: namespace_response, headers: {})
    end
    it "parses a metadata response" do
      namespace_request = described_class.new(session_token: "secretsecret/2/31", id: 1116)
      metadata = namespace_request.metadata
      expect(metadata[:id]).to eq("1116")
      expect(metadata[:path]).to eq("/td-demo-001/pppl")
      expect(metadata[:description]).to eq("Princeton Physics Plasma Lab")
      expect(metadata[:name]).to eq("pppl")
      expect(metadata[:store]).to eq("db")
      expect(WebMock).to have_requested(:post, mediflux_url)
    end

    context "with an namespace instead of an id" do
      before do
        stub_request(:post, mediflux_url)
          .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.namespace.describe\" session=\"secretsecret/2/31\">\n    "\
                      "<args>\n      <namespace>/td-demo-001/pppl</namespace>\n    </args>\n  </service>\n</request>\n")
          .to_return(status: 200, body: namespace_response, headers: {})
      end

      it "parses a metadata response" do
        namespace_request = described_class.new(session_token: "secretsecret/2/31", path: "/td-demo-001/pppl")
        metadata = namespace_request.metadata
        expect(metadata[:id]).to eq("1116")
        expect(metadata[:path]).to eq("/td-demo-001/pppl")
        expect(metadata[:description]).to eq("Princeton Physics Plasma Lab")
        expect(metadata[:name]).to eq("pppl")
        expect(metadata[:store]).to eq("db")
        expect(WebMock).to have_requested(:post, mediflux_url)
      end
    end
  end
end
