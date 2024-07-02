# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::RootCollectionAsset, type: :model, connect_to_mediaflux: true do
  let(:session_token) { Mediaflux::Http::LogonRequest.new.session_token }
  let(:namespace_root) { FFaker::InternetSE.company_name_single_word }
  let(:name) { FFaker::InternetSE.company_name_single_word }

  describe "#create" do
    it "creates the root collection asset" do
      subject = described_class.new(session_token: session_token, namespace: namespace_root, name: name)
      expect(subject.create).to be true

      # make a second call to check that it is idempotent
      subject = described_class.new(session_token: session_token, namespace: namespace_root, name: name)
      expect(subject.create).to be true
    end

    it "detects when an invalid namespace or name is used" do
      subject = described_class.new(session_token: session_token, namespace: "", name: name)
      expect(subject.create).to be false

      subject = described_class.new(session_token: session_token, namespace: namespace_root, name: "")
      expect(subject.create).to be false
    end
  end
end
