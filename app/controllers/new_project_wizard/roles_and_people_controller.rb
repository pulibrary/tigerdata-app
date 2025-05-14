# frozen_string_literal: true
class NewProjectWizard::RolesAndPeopleController < RequestWizardsController
  protected

    def render_current
      @form_url = new_project_roles_and_people_save_path(@request_model)
      render "/new_project_wizard/roles_and_people"
    end

    def render_next
      redirect_to new_project_project_type_path(request_model)
    end

    def render_back
      redirect_to new_project_project_info_dates_path(request_model)
    end
end
