# frozen_string_literal: true
class NewProjectWizard::ProjectInformationCategoriesController < RequestWizardsController
  protected

    def render_current
      render "/new_project_wizard/project_information_categories"
    end

    def render_next
      redirect_to new_project_project_info_dates_path(request_model)
    end

    def render_back
      redirect_to new_project_project_info_path(request_model)
    end
end
