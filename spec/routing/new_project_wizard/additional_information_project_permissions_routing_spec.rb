# frozen_string_literal: true
require "rails_helper"

RSpec.describe NewProjectWizard::AdditionalInformationProjectPermissionsController, type: :routing do
  describe "routing" do
    it "routes to #show" do
      expect(get: "/new-project/additional-info-project-permissions/1").to route_to("new_project_wizard/additional_information_project_permissions#show", "request_id" => "1")
    end

    it "routes to #save" do
      expect(put: "/new-project/additional-info-project-permissions/1/save").to route_to("new_project_wizard/additional_information_project_permissions#save", "request_id" => "1")
    end
  end
end
