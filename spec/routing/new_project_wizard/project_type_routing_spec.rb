# frozen_string_literal: true
require "rails_helper"

RSpec.describe NewProjectWizard::ProjectTypeController, type: :routing do
  describe "routing" do
    it "routes to #show" do
      expect(get: "/new-project/project-type/1").to route_to("new_project_wizard/project_type#show", "request_id" => "1")
    end

    it "routes to #save" do
      expect(put: "/new-project/project-type/1/save").to route_to("new_project_wizard/project_type#save", "request_id" => "1")
    end
  end
end
