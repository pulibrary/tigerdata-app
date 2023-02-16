# frozen_string_literal: true
require "rails_helper"

RSpec.describe Api::V0::ProjectsController do
    render_views

  it "renders the index page" do
    get :index, params: { format: :json }
    expect(response.body).to include("[{")
  end
end
