# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::Connection, type: :model do
  describe "##host" do
    it "returns the mediaflux host" do
      expect(Mediaflux::Http::Connection.host).to eq(Rails.configuration.mediaflux["api_host"])
    end

    context "alternate mediaflux" do
      before do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:alternate_mediaflux, true)
      end

      after do 
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:alternate_mediaflux, false)
      end

      it "returns the mediaflux host" do
        expect(Mediaflux::Http::Connection.host).to eq(Rails.configuration.mediaflux["api_alternate_host"])
      end
    end
  end

  describe "##port" do 
    it "returns the mediaflux port" do
      expect(Mediaflux::Http::Connection.port).to eq(Rails.configuration.mediaflux["api_port"].to_i)
    end  

    context "alternate mediaflux" do
      before do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:alternate_mediaflux, true)
      end

      after do 
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:alternate_mediaflux, false)
      end

      it "returns the alternate mediaflux port" do
        expect(Mediaflux::Http::Connection.port).to eq(Rails.configuration.mediaflux["api_alternate_port"].to_i)
      end
    end
  end

  describe "##transport" do 
  it "returns the mediaflux transport" do
    expect(Mediaflux::Http::Connection.transport).to eq(Rails.configuration.mediaflux["api_transport"])
  end  

  context "alternate mediaflux" do
    before do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:alternate_mediaflux, true)
    end

    after do 
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:alternate_mediaflux, false)
    end

    it "returns the alternate mediaflux transport" do
      expect(Mediaflux::Http::Connection.transport).to eq(Rails.configuration.mediaflux["api_alternate_transport"])
    end
  end
end
end
