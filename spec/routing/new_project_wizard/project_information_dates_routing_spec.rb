# frozen_string_literal: true
require "rails_helper"

RSpec.describe NewProjectWizard::ProjectInformationDatesController, type: :routing do
  describe "routing" do
    it "routes to #show" do
      expect(get: "/new-project/project-info-dates/1").to route_to("new_project_wizard/project_information_dates#show", "request_id" => "1")
    end

    it "routes to #save" do
      expect(put: "/new-project/project-info-dates/1/save").to route_to("new_project_wizard/project_information_dates#save", "request_id" => "1")
    end
  end
end
