# frozen_string_literal: true
require "rails_helper"

RSpec.describe MediafluxInfoController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/mediaflux_info").to route_to("mediaflux_info#index")
    end
  end
end
