# frozen_string_literal: true
require "rails_helper"

RSpec.describe WelcomeController do
  it "renders the index page" do
    get :index
    expect(response).to render_template("index")
    assert_not_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
  end

  context "when a user is logged in", stub_mediaflux: true do
    let(:user) { FactoryBot.create :user }
    before do
      sign_in user
    end

    it "renders the index page" do
      get :index
      expect(response).to render_template("index")
      # this requires a connection to mediaflux... for ease of development we do not want to require this
      # assert_requested(:post, "http://mediaflux.example.com:8888/__mflux_svc__",
      #                  body: /<service name="system.logon">/)
    end
  end
end
