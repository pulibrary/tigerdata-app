# frozen_string_literal: true
class NewProjectWizard::AdditionalInformationProjectPermissionsController < RequestWizardsController
  protected

    def render_current
      add_breadcrumb("New Project Request")
      @request_presenter = NewProjectRequestPresenter.new(@new_project_request)
      @form_url = new_project_additional_information_project_permissions_save_path(@new_project_request)
      render "/new_project_wizard/additional_information_project_permissions"
    end

    def render_next
      redirect_to new_project_additional_information_related_resources_path(new_project_request)
    end

    def render_back
      redirect_to new_project_additional_information_grants_and_funding_path(new_project_request)
    end
end
