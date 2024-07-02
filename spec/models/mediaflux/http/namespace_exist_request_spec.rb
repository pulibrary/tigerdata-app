# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::NamespaceExistRequest, type: :model, connect_to_mediaflux: true do
  let(:session_token) { Mediaflux::Http::LogonRequest.new.session_token }
  let(:namespace_root) { FFaker::InternetSE.company_name_single_word }

  describe "#exist" do
    it "detects whether a namespace exists or not" do
      subject = described_class.new(session_token: session_token, namespace: namespace_root)
      expect(subject.exist?).to be false

      # create the namespace
      Mediaflux::Http::NamespaceCreateRequest.new(session_token: session_token, namespace: namespace_root).resolve

      subject = described_class.new(session_token: session_token, namespace: namespace_root)
      expect(subject.exist?).to be true
    end
  end
end
