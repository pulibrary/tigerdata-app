# frozen_string_literal: true
require "rails_helper"

RSpec.describe Api::V0::ProjectsController do
  render_views

  it "does not work without login" do
    get :index, params: { format: :json }
    expect(response.status).to eq(401)
  end
end
