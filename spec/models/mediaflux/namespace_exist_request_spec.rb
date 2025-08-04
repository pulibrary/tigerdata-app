# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceExistRequest, type: :model, connect_to_mediaflux: true do
  let(:session_token) { Mediaflux::LogonRequest.new.session_token }
  let(:namespace_root) { "/princeton" } # this namespace is already created in the Docker container
  let(:namespace_non_existing) { "/princeton/#{random_project_directory}" }

  describe "#exist" do
    it "detects whether a namespace exists or not" do
      subject = described_class.new(session_token: session_token, namespace: namespace_non_existing)
      expect(subject.exist?).to be false

      subject = described_class.new(session_token: session_token, namespace: namespace_root)
      expect(subject.exist?).to be true
    end
  end
end
