# frozen_string_literal: true
require "rails_helper"

RSpec.describe NewProjectWizard::ProjectInformationController, type: :routing do
  describe "routing" do
    it "routes to #show" do
      expect(get: "/new-project/project-info").to route_to("new_project_wizard/project_information#show")
    end

    context "an id is present" do
      it "routes to #show" do
        expect(get: "/new-project/project-info/1").to route_to("new_project_wizard/project_information#show", "request_id" => "1")
      end
    end

    it "routes to #save" do
      expect(put: "/new-project/project-info/1/save").to route_to("new_project_wizard/project_information#save", "request_id" => "1")
    end
  end
end
