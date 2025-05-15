# frozen_string_literal: true
class NewProjectWizard::StorageAndAccessController < RequestWizardsController
  protected

    def render_current
      @form_url = new_project_storage_and_access_save_path(@request_model)
      render "/new_project_wizard/storage_and_access"
    end

    def render_next
      redirect_to new_project_additional_information_grants_and_funding_path(request_model)
    end

    def render_back
      redirect_to new_project_project_type_path(request_model)
    end
end
