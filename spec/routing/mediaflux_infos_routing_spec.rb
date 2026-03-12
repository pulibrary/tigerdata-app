# frozen_string_literal: true
require "rails_helper"

RSpec.describe SessionInfoController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/session-info").to route_to("session_info#index")
    end
  end
end
