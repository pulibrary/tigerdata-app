# frozen_string_literal: true
require "rails_helper"

RSpec.describe NewProjectWizard::AdditionalInformationGrantsAndFundingController, type: :routing do
  describe "routing" do
    it "routes to #show" do
      expect(get: "/new-project/additional-information-grants-funding/1").to route_to("new_project_wizard/additional_information_grants_and_funding#show", "request_id" => "1")
    end

    it "routes to #save" do
      expect(put: "/new-project/additional-information-grants-funding/1/save").to route_to("new_project_wizard/additional_information_grants_and_funding#save", "request_id" => "1")
    end
  end
end
