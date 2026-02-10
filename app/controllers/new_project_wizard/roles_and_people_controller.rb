# frozen_string_literal: true
class NewProjectWizard::RolesAndPeopleController < RequestWizardsController
  protected

    def render_current
      add_breadcrumb("New Project Request")
      @request_presenter = NewProjectRequestPresenter.new(@new_project_request)
      @form_url = new_project_roles_and_people_save_path(@new_project_request)
      render "/new_project_wizard/roles_and_people"
    end

    def render_next
      # TODO: forward to project type once that screen is implemented
      # redirect_to new_project_project_type_path(new_project_request)
      redirect_to new_project_storage_and_access_path(new_project_request)
    end

    def render_back
      # TODO: Redirect to dates once that screen is implemented
      # redirect_to new_project_project_info_dates_path(new_project_request)
      redirect_to new_project_project_info_path(new_project_request)
    end
end
