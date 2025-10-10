# frozen_string_literal: true
require "rails_helper"
RSpec.describe NewProjectWizard::ReviewAndSubmitController, type: :controller do
  let!(:current_user) { FactoryBot.create(:sysadmin, uid: "tigerdatatester") }
  let(:valid_request) do
    Request.create(project_title: "Valid Request", data_sponsor: current_user.uid, data_manager: current_user.uid, departments: [{ code: "dept", name: "department" }],
                   quota: "500 GB", description: "A valid request", requested_by: current_user.uid,
                   project_folder: random_project_directory, project_purpose: "research")
  end
  let(:session_token) { Mediaflux::LogonRequest.new.session_token }

  describe "#show" do
    it "redirects to sign in if no user is logged in" do
      get :show, params: { request_id: valid_request.id }
      expect(response).to redirect_to "http://test.host/sign_in"
    end

    context "a signed in user" do
      before do
        sign_in current_user
      end

      context "a sysadmin" do
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
        let!(:current_user) { FactoryBot.create(:user) }

        it "redirects to the dashboard" do
          get :show, params: { request_id: valid_request.id }
          expect(response).to redirect_to "http://test.host/dashboard"
        end
        context "the flipper is turned on" do
          before do
            test_strategy = Flipflop::FeatureSet.current.test!
            test_strategy.switch!(:allow_all_users_wizard_access, true)
          end

          after do
            test_strategy = Flipflop::FeatureSet.current.test!
            test_strategy.switch!(:allow_all_users_wizard_access, false)
          end

          it "shows the form when the user is the requestor" do
            get :show, params: { request_id: valid_request.id }
            expect(response).not_to have_http_status(:redirect)
          end

          it "redirects to the dashboard if the user is not the requestor" do
            valid_request.requested_by = FactoryBot.create(:user).uid
            valid_request.save
            get :show, params: { request_id: valid_request.id }
            expect(response).to redirect_to "http://test.host/dashboard"
          end
        end

        context "the production environment" do
          before do
            allow(Rails.env).to receive(:production?).and_return(true)
          end

          it "redirects to the dashboard" do
            get :show, params: { request_id: valid_request.id }
            expect(response).to redirect_to "http://test.host/dashboard"
          end

          it "shows the form if the flipper is flipped" do
            test_strategy = Flipflop::FeatureSet.current.test!
            test_strategy.switch!(:allow_all_users_wizard_access, true)

            get :show, params: { request_id: valid_request.id }
            expect(response).not_to have_http_status(:redirect)

            test_strategy.switch!(:allow_all_users_wizard_access, false)
          end
        end
      end

      context "a tester trainer" do
        let!(:current_user) { FactoryBot.create(:trainer, uid: "tigerdatatester") }

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

          it "redirects to the dashboard" do
            get :show, params: { request_id: valid_request.id }
            expect(response).to redirect_to "http://test.host/dashboard"
          end

          it "shows the form if the flipper is flipped" do
            test_strategy = Flipflop::FeatureSet.current.test!
            test_strategy.switch!(:allow_all_users_wizard_access, true)

            get :show, params: { request_id: valid_request.id }
            expect(response).not_to have_http_status(:redirect)

            test_strategy.switch!(:allow_all_users_wizard_access, false)
          end
        end
      end

      context "a developer" do
        let!(:current_user) { FactoryBot.create(:developer, uid: "tigerdatatester") }

        it "shows the form" do
          get :show, params: { request_id: valid_request.id }
          expect(response).not_to have_http_status(:redirect)
        end

        context "the production environment" do
          before do
            allow(Rails.env).to receive(:production?).and_return(true)
          end

          it "redirects to the dashboard" do
            get :show, params: { request_id: valid_request.id }
            expect(response).to redirect_to "http://test.host/dashboard"
          end

          it "shows the form if the flipper is flipped" do
            test_strategy = Flipflop::FeatureSet.current.test!
            test_strategy.switch!(:allow_all_users_wizard_access, true)

            get :show, params: { request_id: valid_request.id }
            expect(response).not_to have_http_status(:redirect)

            test_strategy.switch!(:allow_all_users_wizard_access, false)
          end
        end
      end

      context "the request is submitted" do
        before do
          valid_request.state = Request::SUBMITTED
          valid_request.save
        end

        context "a sysadmin" do
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
          let!(:current_user) { FactoryBot.create(:user) }

          it "redirects to the dashboard" do
            get :show, params: { request_id: valid_request.id }
            expect(response).to redirect_to "http://test.host/dashboard"
          end

          it "redirects to the dashboard" do
            test_strategy = Flipflop::FeatureSet.current.test!
            test_strategy.switch!(:allow_all_users_wizard_access, true)

            get :show, params: { request_id: valid_request.id }
            expect(response).to redirect_to "http://test.host/dashboard"

            test_strategy.switch!(:allow_all_users_wizard_access, false)
          end

          context "the production environment" do
            before do
              allow(Rails.env).to receive(:production?).and_return(true)
            end

            it "redirects to the dashboard" do
              get :show, params: { request_id: valid_request.id }
              expect(response).to redirect_to "http://test.host/dashboard"
            end
          end
        end

        context "a tester trainer" do
          let!(:current_user) { FactoryBot.create(:trainer, uid: "tigerdatatester") }

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

            it "redirects to the dashboard" do
              get :show, params: { request_id: valid_request.id }
              expect(response).to redirect_to "http://test.host/dashboard"
            end

            it "redirects to the dashboard even if the flipper is flipped" do
              test_strategy = Flipflop::FeatureSet.current.test!
              test_strategy.switch!(:allow_all_users_wizard_access, true)

              get :show, params: { request_id: valid_request.id }
              expect(response).to redirect_to "http://test.host/dashboard"

              test_strategy.switch!(:allow_all_users_wizard_access, false)
            end
          end
        end

        context "a developer" do
          let!(:current_user) { FactoryBot.create(:developer, uid: "tigerdatatester") }

          it "shows the form" do
            get :show, params: { request_id: valid_request.id }
            expect(response).not_to have_http_status(:redirect)
          end

          context "the production environment" do
            before do
              allow(Rails.env).to receive(:production?).and_return(true)
            end

            it "redirects to the dashboard" do
              get :show, params: { request_id: valid_request.id }
              expect(response).to redirect_to "http://test.host/dashboard"
            end

            it "redirects to the dashboard even if the flipper is flipped" do
              test_strategy = Flipflop::FeatureSet.current.test!
              test_strategy.switch!(:allow_all_users_wizard_access, true)

              get :show, params: { request_id: valid_request.id }
              expect(response).to redirect_to "http://test.host/dashboard"

              test_strategy.switch!(:allow_all_users_wizard_access, false)
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
      before do
        sign_in current_user
      end

      context "a sysadmin" do
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
        let!(:current_user) { FactoryBot.create(:user) }

        it "redirects to the dashboard" do
          put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
          expect(response).to redirect_to "http://test.host/dashboard"
        end

        it "updates the request if the flipper is flipped" do
          test_strategy = Flipflop::FeatureSet.current.test!
          test_strategy.switch!(:allow_all_users_wizard_access, true)

          put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
          valid_request.reload
          expect(valid_request.project_title).to eq("Updated title")

          test_strategy.switch!(:allow_all_users_wizard_access, false)
        end

        context "the production environment" do
          before do
            allow(Rails.env).to receive(:production?).and_return(true)
          end

          it "redirects to the dashboard" do
            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            expect(response).to redirect_to "http://test.host/dashboard"
            valid_request.reload
            expect(valid_request.project_title).to eq("Valid Request")
          end

          it "updates the request if the flipper is flipped" do
            test_strategy = Flipflop::FeatureSet.current.test!
            test_strategy.switch!(:allow_all_users_wizard_access, true)

            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Updated title")

            test_strategy.switch!(:allow_all_users_wizard_access, false)
          end
        end
      end

      context "a tester trainer" do
        let!(:current_user) { FactoryBot.create(:trainer, uid: "tigerdatatester") }

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

          it "redirects to the dashboard" do
            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            expect(response).to redirect_to "http://test.host/dashboard"
            valid_request.reload
            expect(valid_request.project_title).to eq("Valid Request")
          end

          it "updates the request if if the flipper is flipped" do
            test_strategy = Flipflop::FeatureSet.current.test!
            test_strategy.switch!(:allow_all_users_wizard_access, true)

            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Updated title")

            test_strategy.switch!(:allow_all_users_wizard_access, false)
          end
        end
      end

      context "a developer" do
        let!(:current_user) { FactoryBot.create(:developer, uid: "tigerdatatester") }

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

          it "updates the request if the flipper is flipped" do
            test_strategy = Flipflop::FeatureSet.current.test!
            test_strategy.switch!(:allow_all_users_wizard_access, true)

            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Updated title")

            test_strategy.switch!(:allow_all_users_wizard_access, false)
          end
        end
      end

      context "the request is submitted" do
        before do
          valid_request.state = Request::SUBMITTED
          valid_request.save
        end

        context "a sysadmin" do
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
          let!(:current_user) { FactoryBot.create(:user) }

          it "does not update the request" do
            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Valid Request")
          end

          it "does not update the request even if the flipper is flipped" do
            test_strategy = Flipflop::FeatureSet.current.test!
            test_strategy.switch!(:allow_all_users_wizard_access, true)

            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
            valid_request.reload
            expect(valid_request.project_title).to eq("Valid Request")

            test_strategy.switch!(:allow_all_users_wizard_access, false)
          end
        end

        context "a tester trainer" do
          let!(:current_user) { FactoryBot.create(:trainer, uid: "tigerdatatester") }

          it "does not update the request" do
            put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
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

            it "does not update the request" do
              put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
              valid_request.reload
              expect(valid_request.project_title).to eq("Valid Request")
            end

            it "does not update even if the flipper is flipped" do
              test_strategy = Flipflop::FeatureSet.current.test!
              test_strategy.switch!(:allow_all_users_wizard_access, true)

              put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
              valid_request.reload
              expect(valid_request.project_title).to eq("Valid Request")

              test_strategy.switch!(:allow_all_users_wizard_access, false)
            end
          end
        end

        context "a developer" do
          let!(:current_user) { FactoryBot.create(:developer, uid: "tigerdatatester") }

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

            it "does not update even if the flipper is flipped" do
              test_strategy = Flipflop::FeatureSet.current.test!
              test_strategy.switch!(:allow_all_users_wizard_access, true)

              put :save, params: { request_id: valid_request.id, request: { project_title: "Updated title" }, commit: "" }
              valid_request.reload
              expect(valid_request.project_title).to eq("Valid Request")

              test_strategy.switch!(:allow_all_users_wizard_access, false)
            end
          end
        end
      end
    end
  end
end
