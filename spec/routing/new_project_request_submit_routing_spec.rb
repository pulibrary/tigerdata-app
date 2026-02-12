# frozen_string_literal: true
require "rails_helper"

RSpec.describe NewProjectRequestSubmitController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/new_project_request_submit").to route_to("new_project_request_submit#index")
    end
  end
end
