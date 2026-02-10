# frozen_string_literal: true
class NewProjectWizard::ProjectInformationDatesController < RequestWizardsController
  protected

    def render_current
      add_breadcrumb("New Project Request")
      @request_presenter = NewProjectRequestPresenter.new(@new_project_request)
      @form_url = new_project_project_info_dates_save_path(@new_project_request)
      render "/new_project_wizard/project_information_dates"
    end

    def render_next
      redirect_to new_project_roles_and_people_path(new_project_request)
    end

    def render_back
      redirect_to new_project_project_info_categories_path(new_project_request)
    end
end
