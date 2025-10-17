# frozen_string_literal: true
class NewProjectWizard::RolesAndPeopleController < RequestWizardsController
  protected

    def render_current
      @request_presenter = RequestPresenter.new(@request_model)
      @form_url = new_project_roles_and_people_save_path(@request_model)
      render "/new_project_wizard/roles_and_people"
    end

    def render_next
      # TODO: forward to project type once that screen is implemented
      # redirect_to new_project_project_type_path(request_model)
      redirect_to new_project_storage_and_access_path(request_model)
    end

    def render_back
      # TODO: Redirect to dates once that screen is implemented
      # redirect_to new_project_project_info_dates_path(request_model)
      redirect_to new_project_project_info_path(request_model)
    end
end
