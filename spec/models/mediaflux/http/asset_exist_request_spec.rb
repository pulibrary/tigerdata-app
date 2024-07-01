# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::AssetExistRequest, type: :model, connect_to_mediaflux: true do
  let(:session_token) { Mediaflux::Http::LogonRequest.new.session_token }
  let(:namespace_root) { Rails.configuration.mediaflux["api_root_collection_namespace"] }
  let(:name) { FFaker::InternetSE.company_name_single_word }

  before do
    create_req = Mediaflux::Http::CollectionAssetCreateRootRequest.new(session_token: session_token, namespace: namespace_root, name: name)
    create_req.resolve
  end

  describe "#exist" do
    it "validates that an asset exist or not" do
      valid_path = "/#{namespace_root}/#{name}"
      subject = described_class.new(session_token: session_token, path: valid_path)
      expect(subject.exist?).to be true

      non_existing_path = "/#{namespace_root}/#{name}-not-existing"
      subject = described_class.new(session_token: session_token, path: non_existing_path)
      expect(subject.exist?).to be false

      non_existing_namespace = "/#{namespace_root}-not-existing/#{name}"
      subject = described_class.new(session_token: session_token, path: non_existing_namespace)
      expect(subject.exist?).to be false
    end
  end
end
