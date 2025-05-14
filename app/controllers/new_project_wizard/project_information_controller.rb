# frozen_string_literal: true
class NewProjectWizard::ProjectInformationController < RequestWizardsController
  protected

    def render_current
      @form_url = new_project_project_info_save_path(@request_model)
      render "/new_project_wizard/project_information"
    end

    def render_next
      redirect_to new_project_project_info_categories_path(request_model)
    end

    def render_back
      redirect_to dashboard_path
    end
end
