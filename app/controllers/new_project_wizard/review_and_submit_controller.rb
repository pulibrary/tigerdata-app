# frozen_string_literal: true
class NewProjectWizard::ReviewAndSubmitController < RequestWizardsController
  layout "wizard_last"

  protected

    def render_current
      add_breadcrumb("New Project Request")
      @request_presenter = NewProjectRequestPresenter.new(@new_project_request)
      @new_project_request.valid_to_submit?
      @form_url = new_project_review_and_submit_save_path(@new_project_request)
      render "/new_project_wizard/review_and_submit"
    end

    def render_next
      if @new_project_request.valid_to_submit?
        @new_project_request.state = NewProjectRequest::SUBMITTED
        @new_project_request.save
        TigerdataMailer.with(request_id: @new_project_request.id, submitter: current_user).request_creation.deliver_now
        redirect_to new_project_request_submit_path
      else
        stubbed_message = "Please resolve errors before submitting your request"
        flash[:notice] = stubbed_message
        redirect_to new_project_review_and_submit_path(new_project_request)
      end
    end

    def render_back
      # TODO: redirect back to additional information when that screen is implemented
      # redirect_to new_project_additional_information_related_resources_path(new_project_request)
      redirect_to new_project_storage_and_access_path(new_project_request)
    end
end
