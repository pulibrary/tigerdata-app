# frozen_string_literal: true
class NewProjectWizard::AdditionalInformationRelatedResourcesController < RequestWizardsController
  protected

    def render_current
      @form_url = new_project_additional_information_related_resources_save_path(@request_model)
      render "/new_project_wizard/additional_information_related_resources"
    end

    def render_next
      redirect_to new_project_review_and_submit_path(request_model)
    end

    def render_back
      redirect_to new_project_additional_information_project_permissions_path(request_model)
    end
end
