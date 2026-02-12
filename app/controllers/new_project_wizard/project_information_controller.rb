# frozen_string_literal: true
class NewProjectWizard::ProjectInformationController < RequestWizardsController
  layout "wizard_first"

  protected

    def render_current
      add_breadcrumb("New Project Request")
      @request_presenter = NewProjectRequestPresenter.new(@new_project_request)
      @wizard_first_step = true
      @form_url = new_project_project_info_save_path(@new_project_request)
      render "/new_project_wizard/project_information"
    end

    def render_next
      # TODO: when categories is implemented forward to it instead or roles
      # redirect_to new_project_project_info_categories_path(new_project_request)
      redirect_to new_project_roles_and_people_path(new_project_request)
    end

    def render_back
      redirect_to dashboard_path
    end
end
