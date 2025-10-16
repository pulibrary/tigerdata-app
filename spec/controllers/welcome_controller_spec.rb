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

    it "renders the index page" do
      get :index
      expect(response).to redirect_to(dashboard_path)
    end
  end

  context "when a user is logged in", connect_to_mediaflux: true do
    let(:user) { FactoryBot.create :user, mediaflux_session: SystemUser.mediaflux_session }
    before do
      sign_in user
    end
  end
end
