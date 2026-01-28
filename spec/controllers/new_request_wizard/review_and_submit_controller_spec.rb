# frozen_string_literal: true
require "rails_helper"
RSpec.describe NewProjectWizard::ReviewAndSubmitController, type: :controller do
  let(:requestor) { FactoryBot.create(:user) }
  let(:valid_request) do
    NewProjectRequest.create(project_title: "Valid Request", data_sponsor: requestor.uid, data_manager: requestor.uid, departments: [{ code: "dept", name: "department" }],
                             quota: "500 GB", description: "A valid request", requested_by: requestor.uid,
                             project_folder: random_project_directory, project_purpose: "research")
  end
  let(:session_token) { Mediaflux::LogonRequest.new.session_token }

  describe "#show" do
    it "redirects to sign in if no user is logged in" do
      get :show, params: { request_id: valid_request.id }
      expect(response).to redirect_to "http://test.host/sign_in"
    end

    context "a signed in user" do
      context "a sysadmin" do
        let!(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "tigerdatatester") }
        before do
          sign_in sysadmin_user
        end

        it "shows the form" do
          get :show, params: { request_id: valid_request.id }
          expect(response).not_to have_http_status(:redirect)
        end

        context "the production environment" do
          before do
            allow(Rails.env).to receive(:production?).and_return(true)
          end

          it "shows the form" do
            get :show, params: { request_id: valid_request.id }
            expect(response).not_to have_http_status(:redirect)
          end
        end
      end

      context "a non elevated user" do
        let!(:researcher_user) { FactoryBot.create(:user) }
        before do
          sign_in researcher_user
        end

        it "redirects to the dashboard" do
          get :show, params: { request_id: valid_request.id }
          expect(response).to redirect_to "http://test.host/dashboard"
        end

        it "shows the form when the user is the requestor" do
          valid_request.requested_by = researcher_user.uid
          valid_request.save
          get :show, params: { request_id: valid_request.id }
          expect(response).not_to have_http_status(:redirect)
        end
      end

      context "a tester trainer" do
        let(:trainer_user) { FactoryBot.create(:trainer) }
        before do
          sign_in trainer_user
        end

        it "redirects to the dashboard" do
          get :show, params: { request_id: valid_request.id }
          expect(response).to have_http_status(:redirect)
        end

        it "shows the form if they are emulating a sysadmin" do
          allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
          allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:emulation_role).and_return("System Administrator")
          get :show, params: { request_id: valid_request.id }
          expect(response).not_to have_http_status(:redirect)
        end

        context "the production environment" do
          before do
            allow(Rails.env).to receive(:production?).and_return(true)
          end

          it "redirects to the dashboard even if they are trying to emulate a sysadmin" do
            allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
            allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:emulation_role).and_return("System Administrator")

            get :show, params: { request_id: valid_request.id }
            expect(response).to redirect_to "http://test.host/dashboard"
          end
        end
      end

      context "a developer" do
        let!(:developer_user) { FactoryBot.create(:developer, uid: "tigerdatatester") }
        before do
          sign_in developer_user
        end

        it "shows the form" do
          get :show, params: { request_id: valid_request.id }
          expect(response).not_to have_http_status(:redirect)
        end

        context "the production environment" do
          before do
            allow(Rails.env).to receive(:production?).and_return(true)
          end

          it "redirects to the dashboard (no special privs for devs in prod)" do
            get :show, params: { request_id: valid_request.id }
            expect(response).to redirect_to "http://test.host/dashboard"
          end
        end
      end

      context "the request is submitted" do
        before do
          valid_request.state = NewProjectRequest::SUBMITTED
          valid_request.save
        end

        context "a sysadmin" do
          let(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "tigerdatatester") }
          before do
            sign_in sysadmin_user
          end

          it "shows the form" do
            get :show, params: { request_id: valid_request.id }
            expect(response).not_to have_http_status(:redirect)
          end

          context "the production environment" do
            before do
              allow(Rails.env).to receive(:production?).and_return(true)
            end

            it "shows the form" do
              get :show, params: { request_id: valid_request.id }
              expect(response).not_to have_http_status(:redirect)
            end
          end
        end

        context "a non elevated user" do
          let!(:researcher_user) { FactoryBot.create(:user) }
          before do
            sign_in researcher_user
          end

          it "redirects to the dashboard" do
            get :show, params: { request_id: valid_request.id }
            expect(response).to redirect_to "http://test.host/dashboard"
          end

          it "does not show the form even when the user is the requestor" do
            valid_request.requested_by = researcher_user.uid
            valid_request.save
            get :show, params: { request_id: valid_request.id }
            expect(response).to have_http_status(:redirect)
          end
        end

        context "a tester trainer" do
          let!(:trainer_user) { FactoryBot.create(:trainer) }
          before do
            sign_in trainer_user
          end

          it "redirects to the dashboard" do
            get :show, params: { request_id: valid_request.id }
            expect(response).to redirect_to "http://test.host/dashboard"
          end

          it "shows the form if they are emulating a sysadmin" do
            allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
            allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:emulation_role).and_return("System Administrator")
            get :show, params: { request_id: valid_request.id }
            expect(response).not_to have_http_status(:redirect)
          end

          context "the production environment" do
            before do
              allow(Rails.env).to receive(:production?).and_return(true)
            end

            it "redirects to the dashboard even if they are trying to emulate a sysadmin" do
              allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
              allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:emulation_role).and_return("System Administrator")

              get :show, params: { request_id: valid_request.id }
              expect(response).to redirect_to "http://test.host/dashboard"
            end
          end
        end

        context "a developer" do
          let!(:developer_user) { FactoryBot.create(:developer) }
          before do
            sign_in developer_user
          end

          it "shows the form" do
            get :show, params: { request_id: valid_request.id }
            expect(response).not_to have_http_status(:redirect)
          end

          context "the production environment" do
            before do
              allow(Rails.env).to receive(:production?).and_return(true)
            end

            it "redirects to the dashboard (no special privs for devs in prod)" do
              get :show, params: { request_id: valid_request.id }
              expect(response).to redirect_to "http://test.host/dashboard"
            end
          end
        end
      end
    end
  end

  describe "#save" do
    it "redirects to sign in if no user is logged in" do
      put :save, params: { request_id: valid_request.id, request: { title: "Updated title" } }
      expect(response).to redirect_to "http://test.host/sign_in"
    end

    context "a signed in user" do
      context "a sysadmin" do
        let!(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "tigerdatatester") }
        before do
          sign_in sysadmin_user
        end
        it "updates the request" do
          put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
          valid_request.reload
          expect(valid_request.project_title).to eq("Updated title")
        end

        context "the production environment" do
          before do
            allow(Rails.env).to receive(:production?).and_return(true)
          end

          it "updates the request" do
            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Updated title")
          end
        end
      end

      context "a non elevated user" do
        let!(:researcher_user) { FactoryBot.create(:user) }
        before do
          sign_in researcher_user
        end

        it "redirects to the dashboard" do
          put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
          expect(response).to redirect_to "http://test.host/dashboard"
        end

        it "updates the request when the user is the requestor" do
          valid_request.requested_by = researcher_user.uid
          valid_request.save
          put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
          valid_request.reload
          expect(valid_request.project_title).to eq("Updated title")
        end
      end

      context "a tester trainer" do
        let!(:trainer_user) { FactoryBot.create(:trainer, uid: "tigerdatatester") }
        before do
          sign_in trainer_user
        end

        it "redirects to the dashboard" do
          put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
          expect(response).to redirect_to "http://test.host/dashboard"
          valid_request.reload
          expect(valid_request.project_title).to eq("Valid Request")
        end

        it "updates the request if they are emulating a sysadmin" do
          allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
          allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:emulation_role).and_return("System Administrator")
          put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
          valid_request.reload
          expect(valid_request.project_title).to eq("Updated title")
        end

        context "the production environment" do
          before do
            allow(Rails.env).to receive(:production?).and_return(true)
          end

          it "does not update the request even when they try to emulate a sysadmin" do
            allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
            allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:emulation_role).and_return("System Administrator")
            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Valid Request")
          end
        end
      end

      context "a developer" do
        let!(:developer_user) { FactoryBot.create(:developer, uid: "tigerdatatester") }
        before do
          sign_in developer_user
        end

        it "updates the request" do
          put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
          valid_request.reload
          expect(valid_request.project_title).to eq("Updated title")
        end

        context "the production environment" do
          before do
            allow(Rails.env).to receive(:production?).and_return(true)
          end

          it "updates does not update the request" do
            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Valid Request")
          end
        end
      end

      context "the request is submitted" do
        before do
          valid_request.state = NewProjectRequest::SUBMITTED
          valid_request.save
        end

        context "a sysadmin" do
          let!(:sysadmin_user) { FactoryBot.create(:sysadmin, uid: "tigerdatatester") }
          before do
            sign_in sysadmin_user
          end
          it "updates the request" do
            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Updated title")
          end

          context "the production environment" do
            before do
              allow(Rails.env).to receive(:production?).and_return(true)
            end

            it "updates the request" do
              put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
              valid_request.reload
              expect(valid_request.project_title).to eq("Updated title")
            end
          end
        end

        context "a non elevated user" do
          let!(:researcher_user) { FactoryBot.create(:user) }
          before do
            sign_in researcher_user
          end

          it "does not update the request" do
            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Valid Request")
          end
        end

        context "a tester trainer" do
          let!(:trainer_user) { FactoryBot.create(:trainer, uid: "tigerdatatester") }
          before do
            sign_in trainer_user
          end

          it "updates the request if they are emulating a sysadmin" do
            allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
            allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:emulation_role).and_return("System Administrator")
            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Updated title")
          end

          context "the production environment" do
            before do
              allow(Rails.env).to receive(:production?).and_return(true)
            end

            it "does not update the request even if they try to emulate a sysadmin" do
              allow_any_instance_of(ActionController::TestSession).to receive(:[]).and_call_original
              allow_any_instance_of(ActionController::TestSession).to receive(:[]).with(:emulation_role).and_return("System Administrator")
              put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
              valid_request.reload
              expect(valid_request.project_title).to eq("Valid Request")
            end
          end
        end

        context "a developer" do
          let!(:developer_user) { FactoryBot.create(:developer, uid: "tigerdatatester") }
          before do
            sign_in developer_user
          end

          it "updates the request" do
            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Updated title")
          end

          context "the production environment" do
            before do
              allow(Rails.env).to receive(:production?).and_return(true)
            end

            it "does not update the request" do
              put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
              valid_request.reload
              expect(valid_request.project_title).to eq("Valid Request")
            end
          end
        end
      end
    end
  end
end
