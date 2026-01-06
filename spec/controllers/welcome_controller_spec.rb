# frozen_string_literal: true
require "rails_helper"

RSpec.describe WelcomeController do
  it "renders the index page" do
    get :index
    expect(response).to render_template("index")
    assert_not_requested(:post, "http://0.0.0.0:8888/")
  end

  it "renders the index page when the system is disabled" do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:disable_login, true)
    get :index
    expect(response).to render_template("index")
    assert_not_requested(:post, "http://0.0.0.0:8888/")
    test_strategy.switch!(:disable_login, false)
  end

  context "when a user is logged in", connect_to_mediaflux: true do
    let(:user) { FactoryBot.create :user, mediaflux_session: SystemUser.mediaflux_session }
    before do
      sign_in user
    end

    it "redirects to the user dashboard" do
      get :index
      expect(response).to redirect_to(dashboard_path)
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

      it "displays a flash message" do
        get :index
        expect(response).to render_template("index")
        expect(flash.notice).to eq("You can not be signed in at this time.")
      end
    end

    context "planned_maintenance is true" do
      before do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:planned_maintenance, true)
      end

      after do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:planned_maintenance, false)
      end

      it "displays a flash message" do
        get :index
        expect(response).to render_template("index")
        expect(flash.notice).to eq("You can not be signed in at this time.")
      end
    end
  end

  context "when a sysadmin user is logged in", connect_to_mediaflux: true do
    let(:user) { FactoryBot.create :sysadmin, mediaflux_session: SystemUser.mediaflux_session }
    before do
      sign_in user
    end

    it "redirects to the user dashboard" do
      get :index
      expect(response).to redirect_to(dashboard_path)
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

      it "displays a flash message and redirects to the user dashboard" do
        get :index
        expect(response).to redirect_to(dashboard_path)
        expect(flash.notice).to eq("System is only enabled for administrators currently")
      end
    end

    context "planned_maintenance is true" do
      before do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:planned_maintenance, true)
      end

      after do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:planned_maintenance, false)
      end

      it "displays a flash message and redirects to the user dashboard" do
        get :index
        expect(response).to redirect_to(dashboard_path)
        expect(flash.notice).to eq("System is only enabled for administrators currently")
      end
    end
  end
end
