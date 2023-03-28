# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Session, type: :model do
  subject(:session) { described_class.new }

  before do
    WebMock.enable!
  end

  after do
    WebMock.disable!
  end

  describe "#logon", stub_mediaflux: true do
    it "authenticates and stores and the session token" do
      session.logon

      expect(session.token).not_to be_nil
    end
  end

  describe "#collections", stub_mediaflux: true do
    it "retrieves the collections from the default namespace" do
      collections = session.collections

      expect(collections).to be_an(Array)
      expect(collections).not_to be_empty
      collection = collections.first
      expect(collection.type).to eq("namespace")
      expect(collection.id).to be_nil
      expect(collection.children).to be_an(Array)
      expect(collection.children).not_to be_empty
      expect(collection.children.first).to be_a(Mediaflux::Collection)
      expect(collection.children.first.id).to eq("1071")
      expect(collection.children.first.type).to eq("namespace")
      expect(collection.children.first.children).to be_empty
    end
  end
end
