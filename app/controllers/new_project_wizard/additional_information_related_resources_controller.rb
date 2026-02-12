# frozen_string_literal: true
class NewProjectWizard::AdditionalInformationRelatedResourcesController < RequestWizardsController
  protected

    def render_current
      add_breadcrumb("New Project Request")
      @request_presenter = NewProjectRequestPresenter.new(@new_project_request)
      @form_url = new_project_additional_information_related_resources_save_path(@new_project_request)
      render "/new_project_wizard/additional_information_related_resources"
    end

    def render_next
      redirect_to new_project_review_and_submit_path(new_project_request)
    end

    def render_back
      redirect_to new_project_additional_information_project_permissions_path(new_project_request)
    end
end
