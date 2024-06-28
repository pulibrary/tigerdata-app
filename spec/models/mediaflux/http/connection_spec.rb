# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::Connection, type: :model do

  describe "##host" do
    it "returns the mediaflux host" do
      expect(Mediaflux::Http::Connection.host).to eq(Rails.configuration.mediaflux["api_host"])
    end

    context "alternate mediaflux host" do
      before do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:alternate_mediaflux, true)
      end
      
      it "returns the mediaflux host" do
        expect(Mediaflux::Http::Connection.host).to eq(Rails.configuration.mediaflux["api_alternate_host"])
      end
    end
  end
end
