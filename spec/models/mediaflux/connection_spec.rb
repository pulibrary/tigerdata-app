# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Connection, type: :model do
  describe "##host" do
    it "returns the mediaflux host" do
      expect(Mediaflux::Connection.host).to eq(Rails.configuration.mediaflux["api_host"])
    end
  end

  describe "##port" do
    it "returns the mediaflux port" do
      expect(Mediaflux::Connection.port).to eq(Rails.configuration.mediaflux["api_port"].to_i)
    end
  end

  describe "##transport" do
    it "returns the mediaflux transport" do
      expect(Mediaflux::Connection.transport).to eq(Rails.configuration.mediaflux["api_transport"])
    end
  end

  describe "##root_collection" do
    it "returns the mediaflux root collection" do
      expect(Mediaflux::Connection.root_collection).to eq(Rails.configuration.mediaflux["api_root_collection"])
    end
  end

  describe "##root_collection_namespace" do
    it "returns the mediaflux root collection namespace" do
      expect(Mediaflux::Connection.root_collection_namespace).to eq(Rails.configuration.mediaflux["api_root_collection_namespace"])
    end
  end

  describe "##root_collection_names" do
    it "returns the mediaflux root collection name" do
      expect(Mediaflux::Connection.root_collection_name).to eq(Rails.configuration.mediaflux["api_root_collection_name"])
    end
  end
  describe "##root_namespace" do
    it "returns the mediaflux root namespace" do
      expect(Mediaflux::Connection.root_namespace).to eq(Rails.configuration.mediaflux["api_root_ns"])
    end
  end
end
