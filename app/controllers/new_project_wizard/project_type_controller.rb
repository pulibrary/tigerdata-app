# frozen_string_literal: true
class NewProjectWizard::ProjectTypeController < RequestWizardsController
  protected

    def render_current
      @request_presenter = RequestPresenter.new(@request_model)
      @form_url = new_project_project_type_save_path(@request_model)
      render "/new_project_wizard/project_type"
    end

    def render_next
      redirect_to new_project_storage_and_access_path(request_model)
    end

    def render_back
      redirect_to new_project_roles_and_people_path(request_model)
    end
end
