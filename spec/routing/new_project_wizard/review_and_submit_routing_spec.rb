# frozen_string_literal: true
require "rails_helper"

RSpec.describe NewProjectWizard::ReviewAndSubmitController, type: :routing do
  describe "routing" do
    it "routes to #show" do
      expect(get: "/new-project/review-submit/1").to route_to("new_project_wizard/review_and_submit#show", "request_id" => "1")
    end

    it "routes to #save" do
      expect(put: "/new-project/review-submit/1/save").to route_to("new_project_wizard/review_and_submit#save", "request_id" => "1")
    end
  end
end
