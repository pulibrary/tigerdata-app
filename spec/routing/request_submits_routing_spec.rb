# frozen_string_literal: true
require "rails_helper"

RSpec.describe RequestSubmitController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/request_submit").to route_to("request_submit#index")
    end
  end
end
