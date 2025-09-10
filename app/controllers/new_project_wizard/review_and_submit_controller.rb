# frozen_string_literal: true
class NewProjectWizard::ReviewAndSubmitController < RequestWizardsController
  protected

    def render_current
      @request_model.valid_to_submit?
      @form_url = new_project_review_and_submit_save_path(@request_model)
      render "/new_project_wizard/review_and_submit"
    end

    def render_next
      if @request_model.valid_to_submit?
        @request_model.state = Request::SUBMITTED
        @request_model.save
        TigerdataMailer.with(request_id: @request_model.id).request_creation.deliver_now
        redirect_to request_path(@request_model.id)
      else
        stubbed_message = "Please resolve errors before submitting your request"
        flash[:notice] = stubbed_message
        redirect_to new_project_review_and_submit_path(request_model)
      end
    end

    def render_back
      # TODO: redirect back to additional information when that screen is implemented
      # redirect_to new_project_additional_information_related_resources_path(request_model)
      redirect_to new_project_storage_and_access_path(request_model)
    end
end
