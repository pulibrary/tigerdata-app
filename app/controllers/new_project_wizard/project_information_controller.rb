# frozen_string_literal: true
class NewProjectWizard::ProjectInformationController < RequestWizardsController
  protected

    def render_current
      @request_presenter = RequestPresenter.new(@request_model)
      @wizard_first_step = true
      @form_url = new_project_project_info_save_path(@request_model)
      render "/new_project_wizard/project_information"
    end

    def render_next
      # TODO: when categories is implemented forward to it instead or roles
      # redirect_to new_project_project_info_categories_path(request_model)
      redirect_to new_project_roles_and_people_path(request_model)
    end

    def render_back
      redirect_to dashboard_path
    end
end
