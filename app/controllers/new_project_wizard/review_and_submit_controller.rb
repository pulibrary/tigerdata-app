# frozen_string_literal: true
class NewProjectWizard::ReviewAndSubmitController < RequestWizardsController
  protected

    def render_current
      @request_model.valid_to_submit?
      @form_url = new_project_review_and_submit_save_path(@request_model)
      render "/new_project_wizard/review_and_submit"
    end

    def render_next
      redirect_to "#{requests_path}/#{@request_model.id}"
    end

    def render_back
      redirect_to new_project_additional_information_related_resources_path(request_model)
    end
end
