# frozen_string_literal: true
require "rails_helper"

RSpec.describe WelcomeController do
  it "renders the index page" do
    get :index
    expect(response).to render_template("index")
    assert_not_requested(:post, "http://0.0.0.0:8888/")
  end

  context "when a user is logged in", connect_to_mediaflux: true do
    let(:user) { FactoryBot.create :user }
    before do
      sign_in user
    end

    it "renders the index page" do
      get :index
      expect(response).to render_template("index")
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
end
