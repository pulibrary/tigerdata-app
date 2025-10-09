# frozen_string_literal: true
require "rails_helper"

RSpec.describe DashboardController do
  it "renders the index page" do
    get :index
    expect(response).to redirect_to("/sign_in")
  end

  context "when a user is logged in", connect_to_mediaflux: true do
    let(:user) { FactoryBot.create :user, mediaflux_session: SystemUser.mediaflux_session }
    before do
      sign_in user
    end

    it "renders the index page" do
      get :index
      expect(response).to render_template("index")
    end
    context "disable_login is true" do
      before do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:disable_login, true)
      end

      after do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:disable_login, false)
      end

      it "redirects to root" do
        get :index
        expect(response).to redirect_to root_path
        expect(flash.notice).to eq("You can not be signed in at this time.")
      end
    end

    it "accepts a post to change the emulation role" do
      user.trainer = true
      user.save!
      post :emulate, params: { emulation_menu: "System Administrator" }
      expect(session[:emulation_role]).to eq "System Administrator"

      get :index, session: session
      expect(assigns(:current_user).sysadmin).to be_truthy
    end

    context "when a trainer is emulating sysadmin" do
      it "renders the index page" do
        user.trainer = true
        user.save!
        get :index, session: { emulation_role: "System Administrator" }
        expect(response).to render_template("index")

        expect(assigns(:current_user).sysadmin).to be_truthy
        expect(assigns(:current_user).eligible_sponsor).to be_falsey
        expect(assigns(:current_user).eligible_manager).to be_falsey
      end

      context "when emulating the role of System Administrator" do
        render_views

        it "shows the admin tab" do
          user.trainer = true
          user.save!
          get :index, session: { emulation_role: "System Administrator" }
          expect(response).to render_template("index")
          expect(response.body).to include("Administration")
        end
      end
    end
    context "when a trainer is emulating eligible_sponsor" do
      it "renders the index page" do
        user.trainer = true
        user.save!
        get :index, session: { emulation_role: "Eligible Data Sponsor" }
        expect(response).to render_template("index")
        expect(assigns(:current_user).sysadmin).to be_falsey
        expect(assigns(:current_user).eligible_sponsor).to be_truthy
        expect(assigns(:current_user).eligible_manager).to be_falsey
      end
    end
    context "when a trainer is emulating eligible_manager" do
      it "renders the index page" do
        user.trainer = true
        user.save!
        get :index, session: { emulation_role: "Eligible Data Manager" }
        expect(response).to render_template("index")

        expect(assigns(:current_user).sysadmin).to be_falsey
        expect(assigns(:current_user).eligible_sponsor).to be_falsey
        expect(assigns(:current_user).eligible_manager).to be_truthy
      end
    end
    context "when a trainer is emulating eligible_data_user" do
      it "renders the index page" do
        user.trainer = true
        user.save!
        get :index, session: { emulation_role: "Eligible Data User" }
        expect(response).to render_template("index")

        expect(assigns(:current_user).sysadmin).to be_falsey
        expect(assigns(:current_user).eligible_sponsor).to be_falsey
        expect(assigns(:current_user).eligible_manager).to be_falsey
      end
    end
  end

  context "when a user is logged in", connect_to_mediaflux: true do
    let(:user) { FactoryBot.create :user, mediaflux_session: SystemUser.mediaflux_session }
    before do
      sign_in user
    end

    context "and the user is a sysadmin" do
      let(:user) { FactoryBot.create :sysadmin, mediaflux_session: SystemUser.mediaflux_session }
      render_views

      it "shows the admin tab" do
        get :index
        expect(response.body).to include("Administration")
      end

      context "disable_login is true" do
        before do
          test_strategy = Flipflop::FeatureSet.current.test!
          test_strategy.switch!(:disable_login, true)
        end

        after do
          test_strategy = Flipflop::FeatureSet.current.test!
          test_strategy.switch!(:disable_login, false)
        end

        it "shows the admin tab" do
          get :index
          expect(response.body).to include("Administration")
          expect(flash.notice).to eq("System is only enabled for administrators currently")
        end
      end
    end

    context "and the user is a developer" do
      let(:user) { FactoryBot.create :developer, mediaflux_session: SystemUser.mediaflux_session }
      render_views

      it "shows the admin tab" do
        get :index
        expect(response.body).to include("Administration")
      end

      context "disable_login is true" do
        before do
          test_strategy = Flipflop::FeatureSet.current.test!
          test_strategy.switch!(:disable_login, true)
        end

        after do
          test_strategy = Flipflop::FeatureSet.current.test!
          test_strategy.switch!(:disable_login, false)
        end

        it "shows the admin tab" do
          get :index
          expect(response.body).to include("Administration")
          expect(flash.notice).to eq("System is only enabled for administrators currently")
        end
      end
    end
  end
end
