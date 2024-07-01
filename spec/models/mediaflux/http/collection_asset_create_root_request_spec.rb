# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::CollectionAssetCreateRootRequest, type: :model, connect_to_mediaflux: true do
  let(:session_token) { Mediaflux::Http::LogonRequest.new.session_token }
  let(:namespace_root) { Rails.configuration.mediaflux["api_root_collection_namespace"] }
  let(:name) { FFaker::InternetSE.company_name_single_word }

  it "creates a collection asset only if it does not exist already" do
      subject = described_class.new(session_token: session_token, namespace: namespace_root, name: name)
      expect(subject.id.to_i).not_to be 0

      subject = described_class.new(session_token: session_token, namespace: namespace_root, name: name)
      expect(subject.id.to_i).to be 0
      expect(subject.response_error[:message].include?("already contains")).to be true
  end
end
