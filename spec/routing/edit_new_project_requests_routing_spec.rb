# frozen_string_literal: true
require "rails_helper"

RSpec.describe EditNewProjectRequestController, type: :routing do
  describe "routing" do
    it "routes to #edit" do
      expect(get: "/edit_new_project_request/1").to route_to("edit_new_project_request#edit", id: "1")
    end

    it "routes to #update via PUT" do
      expect(put: "/edit_new_project_request/1").to route_to("edit_new_project_request#update", id: "1")
    end
  end
end
