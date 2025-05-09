# frozen_string_literal: true
class NewProjectWizard::AdditionalInformationGrantsAndFundingController < RequestWizardsController
  protected

    def render_current
      render "/new_project_wizard/additional_information_grants_and_funding"
    end

    def render_next
      redirect_to new_project_additional_information_project_permissions_path(request_model)
    end

    def render_back
      redirect_to new_project_storage_and_access_path(request_model)
    end
end
