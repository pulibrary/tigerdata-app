# frozen_string_literal: true
require "rails_helper"

RSpec.describe NewProjectWizard::RolesAndPeopleController, type: :routing do
  describe "routing" do
    it "routes to #show" do
      expect(get: "/new-project/roles-people/1").to route_to("new_project_wizard/roles_and_people#show", "request_id" => "1")
    end

    it "routes to #save" do
      expect(put: "/new-project/roles-people/1/save").to route_to("new_project_wizard/roles_and_people#save", "request_id" => "1")
    end
  end
end
