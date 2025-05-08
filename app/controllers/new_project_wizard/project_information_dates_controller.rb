# frozen_string_literal: true
class NewProjectWizard::ProjectInformationDatesController < RequestWizardsController
  protected

    def render_current
      render "/new_project_wizard/project_information_dates"
    end

    def render_next
      redirect_to new_project_roles_and_people_path(request_model)
    end

    def render_back
      redirect_to new_project_project_info_categories_path(request_model)
    end
end
