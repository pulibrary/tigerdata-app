# frozen_string_literal: true
class NewProjectWizard::StorageAndAccessController < RequestWizardsController
  protected

    def render_current
      add_breadcrumb("New Project Request")
      @request_presenter = NewProjectRequestPresenter.new(@new_project_request)
      @form_url = new_project_storage_and_access_save_path(@new_project_request)
      render "/new_project_wizard/storage_and_access"
    end

    def render_next
      # TODO: redirect to additional information when that screen is implemented
      # redirect_to new_project_additional_information_grants_and_funding_path(new_project_request)
      redirect_to new_project_review_and_submit_path(new_project_request)
    end

    def render_back
      # TODO: redirect back to project type when that screen is implemented
      # redirect_to new_project_project_type_path(new_project_request)
      redirect_to new_project_roles_and_people_path(new_project_request)
    end
end
