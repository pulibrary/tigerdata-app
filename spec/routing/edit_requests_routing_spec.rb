# frozen_string_literal: true
require "rails_helper"

RSpec.describe EditRequestsController, type: :routing do
  describe "routing" do
    it "routes to #edit" do
      expect(get: "/admin_edit_request/1").to route_to("edit_requests#edit", id: "1")
    end

    it "routes to #update via PUT" do
      expect(put: "/admin_edit_request/1").to route_to("edit_requests#update", id: "1")
    end
  end
end
